# Process Instructions

## Workflow
### One off tasks
1. Ensure [prerequisites](PREREQUISITES.md) are met.
2. Run init-project-deployment.sh
    ```bash
    $ sh ./init-project-deployment.sh
    This script is about to:
    - Enable the following APIs:
    - Add roles to Cloud Run Service Account:
      
    - Add roles to Cloud Build Service Account:
    
    - Create a Service account for CloudSQL connectivity in Cloud Build
    - Encrypt the Service Account Key with Cloud KMS
    
    Confirm you want to proceed using project: <project_id>.
    Continue? (Y/n) Y
    ```
    If errors occur running this script, it may mean the recently enabled APIs are taking longer than nessesary to be usable, rerunning the script has no adverse side affects. (Errors about conflicts because a service account already exists should be ignored.)

3. Setup Google Cloud Build Github App Integration
- Click Install and follow the directions [here](https://github.com/marketplace/google-cloud-build)
- Ensure the github app is given access to the repository to be deployed.

4. Setup Triggers
https://cloud.google.com/cloud-build/docs/automating-builds/create-github-app-triggers

### Standard workflow
1. git commit
2. git push
3. view cloud build logs and outcomes by following links on the Github website.
