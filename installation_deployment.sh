#!/bin/bash

# Locate the OGG response file
response_file=$(find /tmp/installer -name oggcore.rsp -print -quit)

# OGGCA response file
oggca_rsp_file="/tmp/oggca.rsp"

#-------------------------------------
# Installation of GG in silent mode
#-------------------------------------
function ogg_install() {

    # Locate the runinstaller
    runinstaller="$(find /tmp/installer -name runInstaller | head -1)"

    echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Starting OGG binary silent installation."
    sudo -E -u "${OGG_USER}" "${runinstaller}" -silent -waitforcompletion -ignoreSysPrereqs -showProgress -responseFile "${response_file}"
    
    # Locate the installation log file
    LOG_FILE="$(find /home/ogg/oraInventory/ -name 'installAction*.log' | sort -r | head -1)"
    if [ -f "$LOG_FILE" ]; then
       
        # Check for the exit code 0
        exit_code=$(grep -i "INFO: Exit Status is" "$LOG_FILE" | awk '{print $NF}')
       
        echo "Exit code: $exit_code"
        if [ "$exit_code" == 0 ]; then
           
            ORAINST="$(find /home/ogg/oraInventory/ -name 'orainstRoot*.sh' |head -1)"
           
            echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Executing orainstRoot.sh."
            # Run the root script and capture the output
            orainst_output=$(sudo sh "${ORAINST}" 2>&1)

            # Check if root script successfully executed
            if echo "$orainst_output" | grep -q "The execution of the script is complete"; then
                echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : The execution of the script is complete."
                echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Goldengate 23ai Installation Completed Successfully!."
                # Install Configuration assistant
                oggca_install
            else
                echo "$orainst_output"
                echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : Root script may have failed or incomplete. Please check the output above."
                exit 1
            fi
        else
            echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : Goldengate 23ai Installation failed ! Check the Installation log file."
            exit 1
        fi
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : Verify OraInventory path. Log file not found."
        exit 1
    fi
}

#----------------------------------
# Install configuration assistant
#----------------------------------
function oggca_install() {
   
    # Locate configuration assistant file
    configuration_assistant="$(find "${OGG_HOME/bin}" -name 'oggca.sh' | head -1)"
   
    # Install Configuration Assistant in silent method.
    #echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Installing Deployment."

    # Run Configuration Assistant in background and log output
    sudo -E -u "${OGG_USER}" "${configuration_assistant}" -silent -responseFile "${oggca_rsp_file}" &
    deploy_pid=$!

    spinner='|/-\'
    spin_index=0

    # Show live spinner with timestamp while deployment runs
    while kill -0 "$deploy_pid" 2>/dev/null; do
        printf "\r%s [Working] Installing Deployment %s" "$(date '+%d-%m-%Y %H:%M:%S.%3N')" "${spinner:spin_index++%${#spinner}:1}"
        sleep 0.2
    done

    # Clear spinner line
    printf "\r%-80s\r" " "

    # Wait for deployment to finish and capture exit code
    wait "$deploy_pid"
    deploy_status=$?

    # Get the latest OGGCA log
    oggca_install_log=$(find /home/ogg/oraInventory/ -name "oggcaConfigAction*.log" | sort -r | head -1)

    # Extract exit code from log
    oggca_exit_code=$(grep -i "INFO: Exit Status is" "$oggca_install_log" | awk '{print $NF}')

    echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : OGGCA Exit Code : $oggca_exit_code"

    # Verify success
    if [ $deploy_status -eq 0 ] && [ -n "$oggca_exit_code" ] && [ "$oggca_exit_code" -eq 0 ]; then
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Configuration Assistant completed successfully!."

        #cleanup installer files
        cleanup_installer_files
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : Configuration Assistant failed."
        grep -iE "error|warning" "${oggca_install_log}" || echo "No explicit ERROR/WARNING found in log."
        exit 1
    fi
}

#-------------------------
# Cleanup installer files
#-------------------------
function cleanup_installer_files() {

    # Delete sh scripts
    rm -f /tmp/installation_prereq.sh /tmp/installation_deployment.sh

    # Delete Installer zip
    rm -f "/tmp/${INSTALLER}"

    # Delete the Installer folder
    rm -rf /tmp/installer

    echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Cleanup Done."
}

#--------------
# Entrypoint
#--------------
ogg_install