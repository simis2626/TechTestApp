#!/bin/bash
# This script manages creation of the CloudSQL instance 
# and the management of secrets and SSL certs for connecting to the DB for debugging purposes.

# Variables
INSTANCE_NAME=$(cat $_DB_INSTANCE_SAFE_FILE)
CERT_NAME="debug-cert"
ARTEFACTS_DIR="artefacts/${INSTANCE_NAME}"

# Create artefacts dir if not already present
if [ ! -d $ARTEFACTS_DIR ]; then
    mkdir -p $ARTEFACTS_DIR
fi

# Check for instance existing with expected name. 1=exists
db_exists=$(gcloud sql instances list | grep -e "^${INSTANCE_NAME}\s" | wc -l)

# Only create new CloudSQL instance if doesn't already exist.
if [ $db_exists -eq 0 ]; then
    echo -e "Creating CloudSQL instance: \n Instance Name: ${INSTANCE_NAME}\n Environment: ${APP_ENV}\n GCP Project: ${PROJECT_ID}"

    # Get some random alphanum from machine, strip hyphens for CloudSQL postgres user password.
    # Written in plaintext on the working dir (which isn't persisted after a Cloud Build execution)
    root_password=$(cat /proc/sys/kernel/random/uuid | tr -d "-")
    echo -n $root_password > $_DB_PASSWORD_FILE


    # Test allows the cloudSQL instance to spin down (not setting activation policy)
    # ssl set to ensure security of data and passwords.
    # No Available networks, means no IP connectivity. (only unix sockets)
    TEST_ARGS="--availability-type=zonal \
        --database-version=POSTGRES_11 \
        --maintenance-release-channel=production \
        --require-ssl \
        --root-password=${root_password} \
        --storage-auto-increase \
        --storage-type=HDD \
        --tier=db-f1-micro \
        --no-backup \
        --region=${_GCP_REGION}"

    PROD_ARGS="--activation-policy=always \
        --availability-type=regional \
        --database-version=POSTGRES_11 \
        --maintenance-release-channel=production \
        --require-ssl \
        --root-password=${root_password} \
        --storage-auto-increase \
        --storage-type=SSD \
        --backup \
        --cpu=2 \
        --memory=4GiB \
        --region=${_GCP_REGION}"

    if [ $_APP_ENV = 'PROD' ]; then
        ARGS=$PROD_ARGS
    else
        ARGS=$TEST_ARGS
    fi

    gcloud sql instances create \
        "${INSTANCE_NAME}" \
        $ARGS
    
    # Encrypt the password, and store in the artefacts dir so user can retrieve from GCS and decrypt if debugging required.
    echo -n $root_password | gcloud kms encrypt \
            --plaintext-file=- \
            --ciphertext-file=$ARTEFACTS_DIR/db-postgres-pwd.enc \
            --location=global \
            --keyring=kms-${PROJECT_ID}-techtestapp \
            --key=cloudsql-updatedb 
    echo -e "Database password is encrypted with kms keyring: kms-${PROJECT_ID}-techtestapp \nUsing Key: cloudsql-updatedb\nStored in: db-postgres-pwd.enc "

    #Don't know enough about the application to determine a suitable maintainence window.
    #Unused flags that should be investigated further once performance characteristics and NFRs of the application are well understood.
    #--failover-replica-name="db-tech-test-app-prod-failover" \
    #[--disk-encryption-key=DISK_ENCRYPTION_KEY : --disk-encryption-key-keyring=DISK_ENCRYPTION_KEY_KEYRING --disk-encryption-key-location=DISK_ENCRYPTION_KEY_LOCATION --disk-encryption-key-project=DISK_ENCRYPTION_KEY_PROJECT] \
    #[--database-flags=FLAG=VALUE,[FLAG=VALUE,…]] \
    echo -e "Retrieving client key file, used for IP based connections (intended for debugging)"
    gcloud sql ssl client-certs create "${CERT_NAME}" $ARTEFACTS_DIR/client-key.pem --instance="${INSTANCE_NAME}"
    echo -e "\e[96mDownload the client-key.pem for this instance from the artefacts, it won't be shown again.\e[0m"
else
    echo -e "Not creating instance: ${INSTANCE_NAME}. It already exists."
    echo -e "Staging root_password from previous CloudSQL creation.\nAttempting to decrypt gs://${PROJECT_ID}-${REPO_NAME}/${_APP_ENV}/${BRANCH_NAME}/db-postgres-pwd.enc"
    gsutil cp gs://${PROJECT_ID}-${REPO_NAME}/${_APP_ENV}/${BRANCH_NAME}/db-postgres-pwd.enc - | \
        gcloud kms decrypt --ciphertext-file=- --plaintext-file=${_DB_PASSWORD_FILE} --location=global --keyring=kms-${PROJECT_ID}-techtestapp --key=cloudsql-updatedb
fi
echo -e "Retrieving server certificate authority file."
gcloud sql instances describe "${INSTANCE_NAME}" --format="value(serverCaCert.cert)" >$ARTEFACTS_DIR/server-ca.pem
echo -e "Retrieving client certificate file, used for IP based connections(intending for debugging)"
gcloud sql ssl client-certs describe "${CERT_NAME}" --instance="${INSTANCE_NAME}" --format="value(cert)" >$ARTEFACTS_DIR/client-cert.pem
