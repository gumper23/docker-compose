#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Local functions
function check_mysql_online {
    CONTAINER="${1}"
    echo "#--- Checking readiness of mysql in ${CONTAINER}"
    for (( i=0; i<60; i++ )); do
        echo -n '.'
        docker exec -it "${CONTAINER}" mysqladmin -uroot -proot ping 2>/dev/null | grep "mysqld is alive"
        RETVAL="${?}"
        if [[ "${RETVAL}" -eq 0 ]]; then
            break
        fi
        sleep 1
    done
    return "${RETVAL}"
}

# Script parameters
UP_OR_DOWN="${1:-}"
if [[ "${UP_OR_DOWN}" != 'up' ]] && [[ "${UP_OR_DOWN}" != 'down' ]]; then
    echo "Usage:"
    echo "- first argument: 'up' or 'down'"
    exit 1
fi

# docker compose down --detach errors
if [[ "${UP_OR_DOWN}" == 'up' ]]; then
    docker compose up --detach
else
    docker compose down
    exit 0
fi

# Ensure containers are alive
if ! check_mysql_online master; then
    echo -e "Unable to start master container"
    exit 1
fi
if ! check_mysql_online slave_1; then
    echo -e "Unable to start slave_1 container"
    exit 1
fi
if ! check_mysql_online slave_2; then
    echo -e "Unable to start slave_2 container"
    exit 1
fi

# Create a replication user on the master
docker exec -it master mysql -uroot -proot -e "create user 'repl'@'%' identified by 'repl'"
docker exec -it master mysql -uroot -proot -e "grant replication slave on *.* to 'repl'@'%'"
docker exec -it master mysql -uroot -proot -e "flush privileges"
