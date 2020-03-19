#!/bin/bash

db_name="app"
# Have experienced race conditions with error:
# ERROR: (gcloud.sql.databases.create) HTTPError 409: Operation failed because another operation was already in progress.
sleep 40s 
if [ -z $_DB_INSTANCE_SAFE_FILE ]; then
    echo -e "\e[24m_DB_INSTANCE_SAFE_FILE environment variable not set, exiting\e[0m"
    exit 1
fi

db_instance_name=$(cat "${_DB_INSTANCE_SAFE_FILE}")

db_exists=$(gcloud sql databases list -i $db_instance_name | grep -e "^${db_name}\s" | wc -l)

if [ $db_exists -eq 0 ]; then
    gcloud sql databases create $db_name -i $db_instance_name
else
    echo "CloudSQL DB: ${db_name} already exists in SQL instance: ${db_instance_name}, skipping."
fi
