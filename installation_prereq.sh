#!/bin/bash

# OGGCA response file
oggca_rsp_file="/tmp/oggca.rsp"

# Store the ogg response file parameters in array
parameter_in_response_file=("INSTALL_OPTION" "SOFTWARE_LOCATION" "INVENTORY_LOCATION" "UNIX_GROUP_NAME")

# Store the ogg response file parameter's value in array
parameter_values_in_response_file=("ora23ai" "${OGG_HOME}" "${ORA_INVENTORY}"  "ogg")

# Configuration assistant response file
oggca_response_file="/tmp/oggca.rsp"

# Container hostname in OGGCA
container_host="localhost"

# OGGCA parameters
oggca_parameter_in_response_file=("HOST_SERVICEMANAGER" "DEPLOYMENT_NAME" "ADMINISTRATOR_USER" "ADMINISTRATOR_PASSWORD" "DEPLOYMENT_ADMINISTRATOR_USER"
"DEPLOYMENT_ADMINISTRATOR_PASSWORD" "SERVICEMANAGER_DEPLOYMENT_HOME"  "OGG_SOFTWARE_HOME" "OGG_DEPLOYMENT_HOME" "OGG_ETC_HOME" "OGG_CONF_HOME" 
"OGG_SSL_HOME" "OGG_VAR_HOME" "OGG_DATA_HOME" "OGG_ARCHIVE_HOME" "ENV_LD_LIBRARY_PATH" "ENV_TNS_ADMIN" "PMSRVR_DATASTORE_HOME" 
"SERVICE_MANAGER_REMOTE_METRICS_LISTENING_HOST" "DEPLOYMENT_REMOTE_METRICS_LISTENING_HOST")

# OGGCA parameter values
oggca_parameter_values=("${container_host}" "${DEPLOYMENT_NAME}" "${OGG_ADMIN_USR}" "${OGG_ADMIN_PWD}" "${OGG_ADMIN_USR}" "${OGG_ADMIN_PWD}"
"${OGG_SM_HOME}" "${OGG_HOME}" "${OGG_DM_HOME}" "${OGG_DM_HOME}/etc" "${OGG_DM_HOME}/etc/conf" "${OGG_DM_HOME}/etc/ssl" "${OGG_DM_HOME}/var" 
"${OGG_DM_HOME}/var/lib/data" "${OGG_DM_HOME}/var/lib/archive" "${OGG_HOME}/lib/instantclient:${OGG_HOME}/lib" "${TNS_ADMIN}" 
"${OGG_PM_METRICS}" "${container_host}" "${container_host}")

#---------------------------
# ogg User creation at OS
#---------------------------
function os_ogg_user_creation(){

    # Create a user
    useradd ogg

    # Set password for OGG user
    echo "ogg:ogg123" | chpasswd

    # Change write permision to sudoers file
    chmod 640 /etc/sudoers

    # Add passwordless sudo rules to ogg
    echo "ogg ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

    # Update .bash_profile with environment variables
    BASH_PROFILE="/home/ogg/.bash_profile"

cat <<EOF > "${BASH_PROFILE}"
umask 0022
export OGG_HOME="${OGG_BASE_DIR}/ogg/product/${OGG_VERSION}/ogg_home"
export ORA_INVENTORY="${OGG_BASE_DIR}/app/oraInventory"
export OGG_SCRIPT_DIR="${OGG_BASE_DIR}/scripts"
export TNS_ADMIN="${OGG_DATA_BASE_DIR}/network/admin"
export OGG_DM_HOME="${OGG_DATA_BASE_DIR}/deployment"
export OGG_SM_HOME="${OGG_BASE_DIR}/srvmgr"
export OGG_PM_METRICS="${OGG_BASE_DIR}/metrics"
export OGG_USER="ogg"
export OGG_ETC_HOME="\$OGG_SM_HOME/etc"
export OGG_VAR_HOME="\$OGG_SM_HOME/var"
export ORACLE_HOME="\$OGG_HOME"
export PATH="\$OGG_HOME:\$PATH:\$OGG_HOME/lib/instantclient"
EOF
    echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : ogg user created!!"
}

#---------------------------------------------------
# Create necessary directory & grant permissions
#---------------------------------------------------
function ogg_directory_permission() {

    # Create GoldenGate base directories
    mkdir -p "${OGG_HOME}" \
             "${ORA_INVENTORY}" \
             "${OGG_DATA_BASE_DIR}" \
             "${OGG_DM_HOME}" \
             "${OGG_SM_HOME}" \
             "${OGG_PM_METRICS}" \
             "${OGG_SCRIPT_DIR}" \
             "${TNS_ADMIN}"

    # Exit if directories not created.
    if [ $? -ne 0 ]; then
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : Failed to create directories"
        exit 1
    fi

    # Assign ownership & permissions
    chown -R ogg:ogg "${OGG_BASE_DIR}" "${OGG_DATA_BASE_DIR}"
    chown ogg:ogg "${oggca_rsp_file}"

    chmod -R 0750 "${OGG_BASE_DIR}" "${OGG_DATA_BASE_DIR}"
    echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : Directories created!!"
}

#----------------------------------------
# Unpack the OGG installation software
#----------------------------------------
function ogg_installer_setup() {

    # Create installer directory
    mkdir -p /tmp/installer

    # Validate installer existence
    [[ -f "/tmp/${INSTALLER}" ]] || abort "Source file '${INSTALLER}' does not exist"
   
    # Unzip the OGG software
    unzip -q "/tmp/${INSTALLER}" -d "/tmp/installer" || abort "Unzip operation failed for '${INSTALLER}'"

    # Set ownership to ogg
    chown -R ogg:ogg /tmp/installer/

    # Delete Zip file
    rm -rf "/tmp/${INSTALLER}"
}

#----------------------------------------------------
# Update the response file with appropriate inputs
#----------------------------------------------------
function ogg_update_rsp_file() {
   
    n=0
    # Search for OGG response file
    response_file=$(find /tmp/installer -name oggcore.rsp -print -quit)
    if [ -n "$response_file" ]; then
        for param_v in "${parameter_in_response_file[@]}"; do
            sed -i "s|^$param_v=.*|$param_v=${parameter_values_in_response_file[n]}|" "${response_file}"
            ((n++))
        done
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : OGG response file updated Successfully!!"
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : oggcore.rsp not found!"
        exit 1
    fi
}

#----------------------------------------------------------
# Update the OGGCA response file with appropriate inputs
#----------------------------------------------------------
function oggca_update_rsp_file() {
   
    n=0
    if [ -n "$oggca_response_file" ]; then
        for oggca_param_v in "${oggca_parameter_in_response_file[@]}"; do
            sed -i "s|^$oggca_param_v=.*|$oggca_param_v=${oggca_parameter_values[n]}|" ${oggca_response_file}
            ((n++))
        done
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Info] : OGGCA response file updated Successfully!!"
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S.%3N') [Error] : oggca.rsp not found!"
        exit 1
    fi
}

#--------------
# Entrypoint
#--------------
os_ogg_user_creation
ogg_directory_permission
ogg_installer_setup
ogg_update_rsp_file
oggca_update_rsp_file
