# FastApi template

================

## Description

My project description

[GCP Project](https://console.cloud.google.com/home/dashboard?authuser=0&project=sandbox-sviguier&supportedpurview=project)

## Template Stack

- [FastApi](https://fastapi.tiangolo.com/)
- [SQLModel](https://sqlmodel.tiangolo.com/)
- [SQLAlchemy 2](https://docs.sqlalchemy.org/en/20/)
- [Firestore client](https://firebase.google.com/docs/firestore)
- [Async PostgreSQL client](https://github.com/MagicStack/asyncpg)

## Project Setup

- Install [Poetry](https://python-poetry.org/docs/)

- Set config for venv in local

  ```sh
  poetry config virtualenvs.in-project true
  poetry env use 3.11
  poetry shell
  poetry install --without prod
  ```

- (Postgres only) Create and run required databases

  ```bash
  docker compose up -d
  ```

- (Postgres only) Apply migrations from VSCode launcher

  ```sh
  # For migrations on Cloud SQL instance, ensure creating unix socket & starting Cloud SQL Proxy first
  # sudo mkdir /var/cloudsql && sudo chmod 777 /var/cloudsql
  # cloud-sql-proxy -u /var/cloudsql sandbox-sviguier:europe-west1:fastapi-template-instance
  ```

### Run locally

```sh
# WITHOUT DOCKER (Guess ADC from env)
uvicorn app.main:app --reload          # Or from VSCode launcher

# WITH DOCKER
Run the service named 'app' in docker-compose.yml
```

## Tests

```sh
poetry run pytest --cov=app --cov-report=term     # Uses SQLALCHEMY_DATABASE_URI in pyproject.toml
```

## Application Structure

```bash
fastapi_template
│
├── .cloudbuild                    - Cloud Build configuration
│   └── cloudbuild.yaml
│
├── .github                        
│   └── workflows                  - Github Actions
│
├── .vscode
│   ├── launch.json                - Launch to execute the app
│   └── tasks.json                 - For dockerized launch
│
├── Dockerfile.prod                - Used to build and deploy on Cloud Run
│
├── alembic.ini                    - Local Database configuration
│
├── app                            - Web stuffs
│   ├── api                           - Global deps & routing
│   └── core                          
│      ├── google_apis                  - Google API's utils
│      ├── cloud_logging.py             - Logging wrapper
│      ├── config.py                    - Global app configuration
│      └── google_clients.py            - Google API's client builders
│   │
│   ├── firestore                     - CRUD, Endpoints, Models for Firestore
│   ├── models                        - Common models for Firestore or PostgreSQL
│   ├── sqlmodel                      - CRUD, Endpoints, Models for SQLAlchemy
│   ├── main.py                       - Entrypoint, app instanciation & middleware
│   └── middleware.py                 - Middleware definitions (Metric, Logs, Exceptions)
│
├── iac                            - Terraform resources
│
├── migrations                     - PostgreSQL migrations
│
├── tests                          - PostgresSQL unit tests
│
├── deploy.sh                      - Deployment script
│
├── format.sh                      - Linting and formatting script
│
├── docker-compose.yml             - Provide database local containers
│
├── main.tf                        - Terraform configuration for deployment
│
└── pyproject.toml

```

## Deployment

:warning: Everything under this section assumes you specified **a repository to push to**, a **gcloud project name**, and answered **'yes' to "as_container" question**.

### Initialisation

First, **make sure ADC is configured correctly.**

#### Start a first deployment

- [Connect your repository to Cloud Build](https://console.cloud.google.com/cloud-build/repositories/1st-gen;region=europe-west1?authuser=0&project=sandbox-sviguier&supportedpurview=project)

- Init required resources and start deployment:

```bash
gcloud components update && gcloud components install beta
./deploy.sh -e <dev|staging|prod> # Will get the correct .env.x file & inject variables

# Creates required resources & IAM permissions
# - Secret in Secret Manager filled with .env.dev
# - Cloud Storage bucket to store terraform state
# - Artifact registry repository to store Cloud Run images
# - Required IAM permissions for Cloud Build default SA
#     - run.admin
#     - artifactregistry.admin
#     - datastore.owner
#     - cloudsql.admin
#     - secretmanager.secretAccessor
#     - storage.admin
#     - serviceusage.serviceUsageAdmin
# 
# - Cloud Build trigger to run deployment on push

# Then it starts the Cloud Build trigger
```

Cloud Build is now ready to auto deploy new Cloud Run revision after each push

#### ...or re-deploy the app

```bash
./deploy.sh -e <dev|staging|prod> # Will get the correct .env.x file & inject variables

# - Replaces secret version content if it differs from .env.x
# - Runs the existing Cloud Build trigger
```

## CI/CD

### CI with Github Actions

[**Enable Github Actions API**](https://github.com/sviguier-dgc/fastapi-template-1/actions) in your repository

Actions are configured to run linting for every Pull Request on develop, uat and main branches

### CD with Cloud Build & Terraform

On push, .cloudbuild/cloudbuild.yaml will:

- Build and push new image
- re-apply the iac/main.tf infrastructure to ensure consistency
- Deploy the new Cloud Run revision

Use iac/main.tf to deploy new GCP resources if possible to make terraform aware of it

## Api docs

- [Swagger](http://localhost:8000/api/docs)

## Maintainers

Sébastien Viguier <sebastien.viguier@devoteamgcloud.com>
