#!/usr/bin/env bash

##############################################################################
# Initial revision copied from:
# https://www.percona.com/blog/2018/07/02/fixing-er_master_has_purged_required_gtids-when-pointing-a-slave-to-a-different-master/
##############################################################################
UUID=$1
FIRST_TXN_NO=$2
LAST_TXN_NO=$3

if [[ -z "${UUID}" ]] || [[ -z "${FIRST_TXN_NO}" ]] || [[ -z "${LAST_TXN_NO}" ]]; then
    SCRIPT=$(basename "$0")
    echo -e "Usage: $SCRIPT <UUID> <FIRST_TXN> <LAST_TXN>"
    echo -e "   Ex: ${SCRIPT} 3E11FA47-71CA-11E1-9E33-C80AA9429562 1 5"
    exit 1
fi

while [ "$FIRST_TXN_NO" -le "$LAST_TXN_NO" ]
do
    echo "SET GTID_NEXT='$UUID:$FIRST_TXN_NO';BEGIN;COMMIT;"
    FIRST_TXN_NO=$(( FIRST_TXN_NO + 1 ))
done
echo "SET GTID_NEXT='AUTOMATIC';"