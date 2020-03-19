#!/bin/bash

if [ -z $PROJECT_ID ]; then
    echo -e "\e[24mPROJECT_ID environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $REPO_NAME ]; then
    echo -e "\e[24mREPO_NAME environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $_GCP_REGION ]; then
    echo -e "\e[24m_GCP_REGION environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $_DB_INSTANCE_SAFE_FILE ]; then
    echo -e "\e[24m_DB_INSTANCE_SAFE_FILE environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $_DB_PASSWORD_FILE ]; then
    echo -e "\e[24m_DB_INSTANCE_SAFE_FILE environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $BUILD_ID ]; then
    echo -e "\e[24mBUILD_ID environment variable not set, exiting\e[0m"
    exit 1
fi

db_instance_name=$(cat $_DB_INSTANCE_SAFE_FILE)
db_password=$(cat $_DB_PASSWORD_FILE)

mkdir csql

# Start the docker proxy using the credential file decrypted using kms.
docker run -d -v /workspace/csql:/cloudsql \
  -v /workspace/cloudsql-updatedb.json:/config \
  gcr.io/cloudsql-docker/gce-proxy:1.16 /cloud_sql_proxy -dir=/cloudsql \
  -instances=${PROJECT_ID}:${_GCP_REGION}:${db_instance_name} -credential_file=/config

sleep 5s # Proxy can take some time to become ready.

# Run the built image and trigger an update of the DB, as the DB is managed via Cloud Build the -s flag is passed.
# Uses unix sockets to communicate with CloudSQL.
docker run -v /workspace/csql:/cloudsql \
    -e VTT_DBHOST="/cloudsql/${PROJECT_ID}:${_GCP_REGION}:${db_instance_name}" \
    -e VTT_DBPASSWORD="${db_password}" \
    asia.gcr.io/$PROJECT_ID/$REPO_NAME:$BUILD_ID updatedb -s