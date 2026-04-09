#!/bin/sh
set -euo

# Logging helper
log() {
    level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*"
}

# Verify crond is running
check_crond_up() {
    if ! pgrep crond >/dev/null 2>&1; then
        log ERROR "crond is not running"
        exit 1
    fi

    log INFO "crond is running"
}

# Start the cron daemon in the background
log INFO "starting crond in the background"
crond -f -p -m off &
check_crond_up

# If command-line arguments are passed, execute them
if [ "$#" -gt 0 ]; then
    exec "$@"
fi
