#!/bin/bash
#
# Script requires access to env vars: PROJECT_ID, REPO_NAME, _GCP_REGION
# Checks for presence of bucket and 
#

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

bucket_name="gs://${PROJECT_ID}-${REPO_NAME}"
bucket_created=$(gsutil ls | grep -e "^${bucket_name}/" | wc -l)
if [ $bucket_created -eq 0 ]; then
    echo "Attempting creation of bucket: ${bucket_name}"
    gsutil mb -l $_GCP_REGION gs://$PROJECT_ID-$REPO_NAME
else
    echo "Bucket: ${bucket_name} already exists, skipping."
fi
