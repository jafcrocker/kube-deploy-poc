set -e
set -x
eval HOST_PORT=\${${SERVICE_NAME}_SERVICE_HOST}:\${${SERVICE_NAME}_SERVICE_PORT}
wget --spider $HOST_PORT
wget -qO- $HOST_PORT/version.html | grep "Version 1.0"
