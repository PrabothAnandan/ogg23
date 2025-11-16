#!/bin/bash
set -e

# Path to ServiceManager start script
sm_file="${OGG_SM_HOME}/bin/startSM.sh"
log_file="${OGG_SM_HOME}/var/log/ServiceManager.log"

#----------------------------------------------
# Check if ServiceManager is already running
#----------------------------------------------
function service_health() {
    if ! pgrep -f "[S]erviceManager" > /dev/null; then
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : ServiceManager not running, starting..."
        sudo -E -u "${OGG_USER}" sh "${sm_file}"
        sleep 3
        if pgrep -f "[S]erviceManager"; then
            echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : ServiceManager started...."
        else
            echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : ServiceManager not started, verify logs for more details."
        fi
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : ServiceManager already running."
    fi
}

##
## Entry point
##
#symlink_for_data
service_health

# Tail the log in foreground (keeps container alive)
tail -f "${log_file}" &
wait