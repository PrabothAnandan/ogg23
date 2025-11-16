# **Oracle GoldenGate 23ai MA — Containerized Deployment**

This repository provides a containerized setup for running Oracle GoldenGate 23ai Microservices Architecture (MA) using Podman (or Docker).
It includes a ready-to-use Dockerfile, installation scripts, and an oggca response file (oggca.rsp) used to configure the deployment automatically.

### The purpose of this image is to allow quick setup of GoldenGate 23ai MA for:

Development

Testing

Learning / Sandbox environments


## File Descriptions
|File | Purpose |
|---|---|
|Dockerfile|Builds the GoldenGate 23ai MA container image using the installer zip and provided scripts. |
|installation_prereq.sh|Runs prerequisite checks before installation (packages, permissions, environment setup).|
|installation_deployment.sh|Performs the silent installation of OGG and deployment of GoldenGate MA using the oggca.rsp response file. |
|healthcheck.sh|Basic health check script to verify SM status and keep the container live.|
|oggca.rsp|Response file that defines installation configuration including ports, deployment name, admin credentials, directories etc.|

### Build Image 
```
podman / docker build \
  --build-arg INSTALLER_FILE=V1042871-01.zip \
  --build-arg OGG_ADMIN=<OGG_USER> \
  --build-arg OGG_ADMIN_PWD=<OGG_USR_PWD> \
  --build-arg DEPLOYMENT=<DEPLOYMENT_NAME> \
  -t oracle/ogg23:23.4.1.24.05 .
  ```
### To run oracle goldengate in container
```
podman / docker run -d --name <container_name> \
-p 9000-9004:9000-9004 \
-v [houst mount]:/gg02 \
oracle/ogg23:23.4.1.24.05
```
