# -----------------------------------------------------------------------------
FROM alpine:latest

# Install packages
RUN apk update && \
    apk add --no-cache tini curl grep jq

# Copy required scripts and tools
WORKDIR /
COPY --chmod=555 ./rootfs/ .

# Setup entrypoint and default cmd
ENTRYPOINT ["/sbin/tini", "--", "/opt/entrypoint.sh"]
CMD ["schedule"]
