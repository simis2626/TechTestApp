#!/bin/bash
# Depends on being having access to environment variable: DB_INSTANCE_NAME

if [ -z $DB_INSTANCE_NAME ]; then
    echo -e "\e[24mDB_INSTANCE_NAME environment variable not set, exiting\e[0m"
    exit 1
fi
db_instance_name_safe=$(echo -n "db-${DB_INSTANCE_NAME,,}" | tr -dc "[:alnum:]-")
echo -e  "writing safe db name: ${db_instance_name_safe} to /workspace/_instance_name_safe"
echo "${db_instance_name_safe}">/workspace/_instance_name_safe
