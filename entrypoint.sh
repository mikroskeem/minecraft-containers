#!/bin/sh

# Ensure that we're in home directory
cd /home/container || {
    echo ">>> FAILED TO CHANGE DIRECTORY TO /home/container!"
    exit 1
}

# Output Current Java Version
java -version

# Make internal Docker IP address available to processes.
INTERNAL_IP="$(ip route get 1 | awk '{print $NF;exit}')"
export INTERNAL_IP

# Debug shell
if [ -f .debugshell ]; then
    echo ">>> Do not forget to delete /home/container/.debugshell to launch your server normally."
    exec /bin/sh -i
fi

# Replace Startup Variables
MODIFIED_STARTUP="$(eval echo "$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")"
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Source .env file if present
if [ -f .env ]; then
    . .env
fi

# Run the Server
eval "${MODIFIED_STARTUP}"
