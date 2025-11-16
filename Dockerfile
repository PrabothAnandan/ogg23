#########################################
# Initial Verion : Praboth Anandan      #
#########################################

# Use the official Oralce Linux base image
FROM oraclelinux:8

# Define build arguments
ARG INSTALLER_FILE
ARG OGG_ADMIN
ARG OGG_ADMIN_PWD
ARG DEPLOYMENT

ENV INSTALLER=${INSTALLER_FILE} 
ENV OGG_ADMIN_USR=${OGG_ADMIN} 
ENV OGG_ADMIN_PWD=${OGG_ADMIN_PWD}


# Install basic packages into the container unzip, hostname, sudo, libaio for sqlplus and procps for ps -ef|grep
RUN dnf install -y unzip sudo hostname  && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Set the environments

# GG installation base mount point
ENV OGG_BASE_DIR "/gg01" 
ENV OGG_DATA_BASE_DIR "/gg02" 
ENV DEPLOYMENT_NAME=${DEPLOYMENT} 
ENV OGG_VERSION "23"

#ENV HOME "${GG_BASE_DIR}"
ENV OGG_HOME "${OGG_BASE_DIR}/ogg/product/${OGG_VERSION}/ogg_home" 
ENV ORA_INVENTORY "${OGG_BASE_DIR}/app/oraInventory" 
ENV OGG_SCRIPT_DIR "${OGG_BASE_DIR}/scripts" 
ENV TNS_ADMIN "${OGG_DATA_BASE_DIR}/network/admin" 
ENV OGG_DM_HOME "${OGG_DATA_BASE_DIR}/deployment" 
ENV OGG_SM_HOME "${OGG_BASE_DIR}/srvmgr" 
ENV OGG_PM_METRICS "${OGG_BASE_DIR}/metrics" 
ENV OGG_USER "ogg" 
ENV ROOT_USER "root" 
ENV OGG_ETC_HOME "${OGG_SM_HOME}/etc" 
ENV OGG_VAR_HOME "${OGG_SM_HOME}/var" 
ENV ORACLE_HOME "${OGG_HOME}" 
ENV PATH "${OGG_HOME}:${PATH}:${OGG_HOME}/lib/instantclient"

# Copy the Goldengate Installer to temp location
COPY ${INSTALLER} /tmp/

# Copy the installation_prereq.sh, installation_deployment.sh and oggca.rsp.
COPY installation_prereq.sh installation_deployment.sh oggca.rsp /tmp/

# Copy the health check script
COPY healthcheck.sh /usr/local/bin

# Execute the installation_prereq.sh file to create directory and grant permissions
RUN bash -c /tmp/installation_prereq.sh

# Execute the installation_deployment.sh file to install the GGMA
RUN bash -c /tmp/installation_deployment.sh

# Switch user
USER ogg

# Working dir
WORKDIR /home/ogg

# Set the default command
CMD ["/usr/local/bin/healthcheck.sh"]

