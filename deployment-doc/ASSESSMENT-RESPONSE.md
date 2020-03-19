# Assessment

Candidates should assume that the solution will be deployed to an empty cloud subscription with no existing infrastructure in place.
> Solution will need to ensure all APIs and account permissions are present.

Candidates should provide documentation on their solution, including:

- [Pre requisites for your deployment solution.](PREREQUISITES.md)
- [High level architectural overview of your deployment.](ARCHITECTURE.md)
- [Process instructions for provisioning your solution.](PROCESS_INSTRUCTIONS.md)

## Assessment Grading Criteria

### Key Criteria

Candidates should take care to ensure that thier submission meets the following criteria:

- Must be able to start from a cloned git repo.
> Will provide init script and ability to submit builds from developer machine.
- Must document any pre-requisites clearly.
> [PREQUISITES.md](PREQUISITES.md)
- Must be contained within a GitHub repository.
> https://github.com/simis2626/TechTestApp
- Must deploy via an automated process.
> Using [Google Cloud Build](https://cloud.google.com/cloud-build)

### Grading

Candidates will be assessed across the following categories:

#### Coding Style

- Clarity of code
- Comments where relevant
- Consistency of Coding

#### Security

- Network segmentation (if applicable to the implementation)
> CloudSQL is deployed with no 'Authorized Networks' meaning that it is totally inaccessible over IP. The only connection method is via unix sockets which requires the IAM role cloudsql.{client, admin}<br/>
> Note the external IP is a requirement of Cloud Run (see [docs](https://cloud.google.com/sql/docs/postgres/connect-run#setting_up_a_instance))
- Secret storage
> Unencrypted secrets are available on the filesystem of the Cloud Builder, only during the duration of the build and are not persisted.</br>
> Persistent secrets are encrypted with CloudKMS and stored on a GCS bucket which requires IAM access to GCS to access & KMS access to decrypt.
- Platform security features
> The use of unix sockets for CloudSQL connectivity is supported by the platform, and allows the CloudSQL instance to be totally blocked in terms of IP access (as well as having SSL required).


#### Simplicity

- No superfluous dependencies
- Do not overengineer the solution

#### Resiliency

- Auto scaling and highly available frontend
> Cloud Run is Regional (meaning that it will failover between zones).<br/>
> Being 'serverless' it is also auto scaling (configurable)<br/>
> Ref: https://cloud.google.com/run#all-features
- Highly available Database
> CloudSQL when started with `--availability-type=regional ` is highly available.<br/>
> Ref: https://cloud.google.com/sql#all-features, https://cloud.google.com/sdk/gcloud/reference/sql/instances/create#--availability-type

## Tech Test Application

Single page application designed to be ran inside a container or on a vm (IaaS) with a postgres database to store data.

It is completely self contained, and should not require any additional dependencies to run.

## Install

1. Download latest binary from release
2. unzip into desired location
3. and you should be good to go

## Start server

update `conf.toml` with database settings

`./TechTestApp updatedb` to create a database and seed it with test data

`./TechTestApp serve` will start serving requests

## Interesting endpoints

`/` - root endpoint that will load the SPA

`/api/tasks/` - api endpoint to create, read, update, and delete tasks

`/healthcheck/` - Used to validate the health of the application

## Compile from source

### Requires

#### dep

`curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh`

### Process

`go get -d github.com/Servian/TechTestApp`

run `build.sh`

the `dist` folder contains the compiled web package

### Docker build

`docker build . -t techtestapp:latest`