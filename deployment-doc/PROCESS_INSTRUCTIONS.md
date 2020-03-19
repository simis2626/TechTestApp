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
- Once redirected to Google Cloud Console:
    1. Select the GCP project being used for this application.
    2. Select the Github Repo to connect.
    3. Accept the default trigger.

    **Advanced**

    As a note, this deployment pipeline supports 'test' deployments, where the CloudSQL instance is zonal and lower spec'd. And the Cloud Run deployment deploys to a 'repo_name-test' service so you can evaluate changes prior to deploying to production.

    The default behaviour, with the default branch trigger is that any push on any branch is treated as a new production deployment.

    If two separate triggers are setup: one matching branches ^master$ and the other matching the inverse of ^master$ (where a substitution variable is set where _APP_ENV is set to `TEST`). The alternate flow will be used, where a smaller, seperately managed test branch is provisioned.
 See [Creating Github Triggers](https://cloud.google.com/cloud-build/docs/automating-builds/create-github-app-triggers) for more information on this.

### Standard workflow
1. git commit
2. git push
3. view cloud build logs and outcomes by following links on the Github website.
