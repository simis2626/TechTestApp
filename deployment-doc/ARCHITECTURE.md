# Architecture

# Initial Sketch Plan
To get a rough idea of the initial plan, [this sketch](https://drive.google.com/file/d/1hXsk8ZEmxIllxzusgBcEIPhh6iTS2Qfh/view?usp=sharing) was completed to keep the workflow structured.

# Architecture Diagram
An Architecture Diagram of the solution and the way the cloud build steps orchestrate the deployment is available [in Google Drive](https://drive.google.com/open?id=12DgV6AWKf4j6okznSyTv5YGDuAt19QZ9)

# Cloud Build Steps
1. calc-safe-instance-name

    CloudSQL Instances can only use lowercase alphanumeric and hyphens.<br/>
    This script creates an instance name, and saves it to a well known location on disk.

1. create-gcs-bucket
1. decrypt-cloudsql-updatedb-cred
1. create-cloud-sql
1. create-sql-database
1. build-docker
1. publish-docker
1. update-db
1. deploy-cloud-run