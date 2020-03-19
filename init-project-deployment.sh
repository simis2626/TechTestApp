#!/bin/bash

# This script is designed to be run once, to perform initial setup activities for 
# the GCP project being used to deploy this application.
#

# Stop ugly and uninformative add-iam-policy-binding output.
GCP_FLAGS="-q --no-user-output-enabled"

# Current Project
project_name=$(gcloud config get-value project)

echo -en "This script is about to add several roles to Cloud Build and Cloud Run Default Service Accounts within project: ${project_name}.\nIt will also enable the required APIs (see README.md) and create a service account specific to Cloud KMS Continue (Y/n)"
read -n 1 -r confirm
echo
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Cancelling safely. No changes were made."
    exit 1
fi

# Enable required APIs
gcloud services enable \
  sqladmin.googleapis.com \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  cloudkms.googleapis.com

echo "Waiting 3 minutes for enabled APIs to be available for use."
#sleep 180s

# Get current project number, used as part of Service account names.
project_number=$(gcloud projects describe ${project_name} | grep projectNumber |awk '{print $2}'| tr -d "'")

# Required to allow cloud build to create and otherwise fully manage cloudSQL instances.
echo "Adding roles/cloudsql.admin to Cloud Build Service Account"
gcloud ${GCP_FLAGS} projects add-iam-policy-binding ${project_name} \
  --member serviceAccount:${project_number}@cloudbuild.gserviceaccount.com \
  --role roles/cloudsql.admin

# Required to allow Cloud Build to perform CRUD operations on Cloud Run.
echo "Adding roles/run.admin to Cloud Build Service Account" 
gcloud ${GCP_FLAGS} projects add-iam-policy-binding ${project_name} \
  --member serviceAccount:${project_number}@cloudbuild.gserviceaccount.com \
  --role roles/run.admin

# Allows cloud build to impersonate the Cloud Run Service account which is required for cloud build to perform a successful deployment.
# See https://cloud.google.com/cloud-build/docs/deploying-builds/deploy-cloud-run#required_iam_permissions
# If I had more time I'd work out how to limit the scope of this grant better, or if not possible, for a real life scenario I would direct the 
# user to complete the action as described at the link above in the Console.
echo "Adding roles/iam.serviceAccountUser to Cloud Build Service Account, (lets the account impersonal Cloud Run SA)"
gcloud ${GCP_FLAGS} projects add-iam-policy-binding ${project_name} \
  --member serviceAccount:${project_number}@cloudbuild.gserviceaccount.com \
  --role roles/iam.serviceAccountUser

# Permission for compute service account (Cloud Run SA) to connect to Cloud SQL as a Client.
echo "Adding roles/cloudsql.client to Compute Run Service Account" 
gcloud ${GCP_FLAGS} projects add-iam-policy-binding ${project_name} \
  --member serviceAccount:${project_number}-compute@developer.gserviceaccount.com \
  --role roles/cloudsql.client

# Required to allow Cloud Build to perform access and use kms 
echo "Adding roles/cloudkms.cryptoKeyEncrypterDecrypter to Cloud Build Service Account" 
gcloud ${GCP_FLAGS} projects add-iam-policy-binding ${project_name} \
  --member serviceAccount:${project_number}@cloudbuild.gserviceaccount.com \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter

# Create service account specifically for cloudsql proxy to use in cloud build.
echo "Creating service account to allow Cloud Build to connect to CloudSQL, via CloudSQL Proxy" 
gcloud ${GCP_FLAGS} iam service-accounts create cloudsql-updatedb \
  --description="SA for running update DB command inside Cloud Build, Required as Cloud Build can't connect via unix sockets, so need to bootstrap the cloud sql proxy with these credentials"

# Give the newly create SA access to cloudsql as a client (required by CloudSQL proxy).
echo "Adding roles/cloudsql.client to service account to allow Cloud Build to connect to CloudSQL, via CloudSQL Proxy" 
gcloud ${GCP_FLAGS} projects add-iam-policy-binding ${project_name} \
  --member serviceAccount:cloudsql-updatedb@${project_name}.iam.gserviceaccount.com \
  --role roles/cloudsql.client

# Create the key file for this service account, which will be encrypted with kms so it can be stored with code.
echo "Downloading key file for service account to allow Cloud Build to connect to CloudSQL, via CloudSQL Proxy" 
gcloud ${GCP_FLAGS} iam service-accounts keys create ./cloudsql-updatedb.json \
  --iam-account cloudsql-updatedb@${project_name}.iam.gserviceaccount.com

# Create a KMS Keyring
echo "Creating CloudKMS KeyRing to enable Secrets encryption" 
gcloud ${GCP_FLAGS} kms keyrings create kms-${project_name}-techtestapp \
  --location=global

# Create a key stored in KMS to be used for encryption.
echo "Creating CloudKMS key to enable Secrets encryption" 
gcloud ${GCP_FLAGS} kms keys create cloudsql-updatedb \
  --location=global \
  --keyring=kms-${project_name}-techtestapp \
  --purpose=encryption

# Encrypt the keyfile.
echo "Encrypting the Service Account keyfile, so it can be stored in code and accessible to Cloud Build." 
gcloud kms encrypt \
  --plaintext-file=./cloudsql-updatedb.json \
  --ciphertext-file=./cloudsql-updatedb.json.enc \
  --location=global \
  --keyring=kms-${project_name}-techtestapp \
  --key=cloudsql-updatedb

rm ./cloudsql-updatedb.json
echo; echo;
echo "The file ./cloudsql-updatedb.json.enc must be committed to your source code, at the root of the project directory."