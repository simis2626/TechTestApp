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
    echo -e "\e[24m_DB_PASSWORD_FILE environment variable not set, exiting\e[0m"
    exit 1
fi

if [ -z $BUILD_ID ]; then
    echo -e "\e[24mBUILD_ID environment variable not set, exiting\e[0m"
    exit 1
fi

db_instance_name=$(cat $_DB_INSTANCE_SAFE_FILE)

function cloud_run_name(){
    if [ $_APP_ENV = 'PROD' ]; then
        echo -n "${REPO_NAME,,}"
    else
        echo -n "${REPO_NAME,,}-${_APP_ENV,,}"
    fi
}

db_password=$(cat ${_DB_PASSWORD_FILE})

gcloud run deploy $(cloud_run_name) \
  --image "asia.gcr.io/$PROJECT_ID/$REPO_NAME:$BUILD_ID" \
  --region $_GCP_REGION \
  --platform managed \
  --allow-unauthenticated \
  --port '3000' \
  --args serve \
  --add-cloudsql-instances ${PROJECT_ID}:${_GCP_REGION}:${db_instance_name} \
  --set-env-vars VTT_DBHOST="/cloudsql/${PROJECT_ID}:${_GCP_REGION}:${db_instance_name}",VTT_DBPASSWORD="${db_password}",VTT_LISTENHOST=""
# Viper autoenv is used to supply run time level env variables for the database, and erasing the 'localhost' default listenhost which causes issues with cloud run.
