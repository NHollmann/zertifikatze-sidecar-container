#!/bin/sh

##
## ENVIRONMENT VARIABLES
##

if [[ -z "${API_URL}" ]]; then
    echo "Missing Zertifikatze URL" > /dev/stderr
    export CONFIG_ERROR=1
fi

if [[ -z "${CERT_DIRECTORY}" ]]; then
    export CERT_DIRECTORY="/certs"
fi

if [[ -z "${LOAD_SCHEDULE}" ]]; then
    export LOAD_SCHEDULE="0 3 * * *"
fi

if [[ -z "${CERT_NAME}" ]]; then
    echo "Missing cert name" > /dev/stderr
    export CONFIG_ERROR=1
fi

if [[ -z "${CERT_API_KEY}" ]]; then
    echo "Missing cert api key" > /dev/stderr
    export CONFIG_ERROR=1
fi

if [[ -z "${CERT_TYPE}" ]]; then
    export CERT_TYPE="pem"
fi

if [[ "${CERT_TYPE}" != "pfx" && "${CERT_TYPE}" != "pem" ]]; then
    echo "Incorrect cert type, only pfx and pem are supported" > /dev/stderr
    export CONFIG_ERROR=1
fi

##
## SETUP CRONTAB
##

echo "${LOAD_SCHEDULE} /opt/update-cert.sh" | crontab -

##
## SUBCOMMANDS
##

tool_help(){
    echo "Subcommands:"
    echo "    schedule     Start certificate scheduler"
    echo "    shell        Start a shell in the container"
    echo "    load         Do a single certificate load"
    echo ""
}

tool_schedule(){
    if [[ ! -z "${CONFIG_ERROR}" ]]; then
        echo "Abort: cannot load certificate with missing configuration" > /dev/stderr
        exit 1
    fi
    /opt/update-cert.sh
    /usr/sbin/crond -f -l 8 -L /dev/stdout
}

tool_shell(){
    /bin/sh
}

tool_load(){
    if [[ ! -z "${CONFIG_ERROR}" ]]; then
        echo "Abort: cannot load certificate with missing configuration" > /dev/stderr
        exit 1
    fi
    /opt/update-cert.sh
}

# Parse Subcommand
subcommand=$1
case $subcommand in
    "" | "-h" | "--help")
        tool_help
        ;;
    *)
        shift
        if type tool_${subcommand} &>/dev/null; then 
            tool_${subcommand} $@
        else
            echo "Error: '$subcommand' is not a known subcommand." >&2
            exit 1
        fi
        ;;
esac
