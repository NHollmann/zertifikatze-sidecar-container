#!/bin/sh

set -eu

export PATH="/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
cd "$(dirname "$0")"
startTime=`date +%s`

# Workdir setup
WORKDIR="${CERT_DIRECTORY}"
mkdir -p "$WORKDIR"

# Check if we already have a version
VERSION_FILE="$WORKDIR/current-version"
CURRENT_VERSION=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
fi

# Check if there is a new version of the certificate
RESPONSE=$(curl -fsS \
    -H "Authorization: Bearer $CERT_API_KEY" \
    -H "X-Current-Version: $CURRENT_VERSION" \
    "$API_URL/api/v1/certs/$CERT_NAME" \
    -w "\n%{http_code}")

HTTP_CODE=$(printf "%s" "$RESPONSE" | tail -n1)
BODY=$(printf "%s" "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "204" ]; then
    echo "Certificate already up to date."
    exit 0
fi

if [ "$HTTP_CODE" != "200" ]; then
    echo "Certificate check failed."
    exit 1
fi

# We have a new Version!
NEW_VERSION=$(printf "%s" "$BODY" | jq -r '.version')
echo "New certificate version available: $NEW_VERSION"

# Download the certificate depending on the choosen type
if [ "$CERT_TYPE" = "pem" ]; then
    JSON_FILE="$WORKDIR/cert.json"

    curl -fsS \
        -H "Authorization: Bearer $CERT_API_KEY" \
        "$API_URL/api/v1/certs/$CERT_NAME/download/pem" \
        -o "$JSON_FILE"

    jq -r '.cert' "$JSON_FILE" > "$WORKDIR/cert.pem"
    chmod 600 "$WORKDIR/cert.pem"

    jq -r '.chain' "$JSON_FILE" > "$WORKDIR/fullchain.pem"
    chmod 600 "$WORKDIR/fullchain.pem"

    jq -r '.key' "$JSON_FILE" > "$WORKDIR/key.pem"
    chmod 600 "$WORKDIR/key.pem"
else
    TEMP_FILE="$WORKDIR/cert.pfx.tmp"
    TARGET_FILE="$WORKDIR/cert.pfx"

    curl -fsS \
        -H "Authorization: Bearer $CERT_API_KEY" \
        "$API_URL/api/v1/certs/$CERT_NAME/download/pfx" \
        -o "$TEMP_FILE"

    mv "$TEMP_FILE" "$TARGET_FILE"
    touch "$TARGET_FILE"
    chmod 600 "$TARGET_FILE"
fi

# Save current version
printf "%s" "$NEW_VERSION" > "$VERSION_FILE"
chmod 600 "$VERSION_FILE"

# Measure execution time
endTime=`date +%s`
runTime=$((endTime-startTime))

echo "Certificate updated successfully."
echo "Run finished at $(date) after $runTime seconds."

# Run post update command
if [ -n "$POST_UPDATE_CMD" ]; then
    echo "Run POST_UPDATE_CMD..."
    eval "$POST_UPDATE_CMD"
fi
