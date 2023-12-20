#!/bin/sh
echo "start entrypoint.sh" 
ssh-keygen -A
exec /usr/sbin/sshd -D -e "$@"
echo "done entrypoint.sh"

# chmod +x -v entrypoint.sh



