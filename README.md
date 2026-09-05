# MIBApp Workflow Repo
This repository orchestrates CI/CD deployment for services using Helm, AWS, and GitHub Actions. Below is an overview of the key directories and their roles in the pipeline:

---
## Directory Structure & Purpose
### `env/`
- Contains service-related configuration files for each environment (e.g., `env/ai-auth-service/sit/config.yaml`).
- Used to specify:
	- **Cluster name** for deployment
	- **AWS IAM Role ARN** for role assumption
	- **Ingress installation flag** (whether ingress should be deployed)
- The pipeline reads these configs to determine deployment targets and options.

### `helm/`
- Source for Kubernetes deployments using Helm charts.
- Structure:
	- `helm/<service>/service/` — Helm chart for the service
- The pipeline installs service charts based on the environment configuration in `env/`.

### `secrets/`
- Contains secret configuration files to be uploaded to AWS Secrets Manager.
- **Path mapping:**
	- Each secret is uploaded under the name `<service>_<key>` or as a JSON object with nested keys.
	- Example: `secrets/ai-auth-service/sit/tls_cert.yaml` → AWS Secrets Manager secret named `ai-auth-service_tls_cert`.
- Secrets are referenced in Helm values and injected at runtime.

### `ssl-cert/`
- Stores SSL certificates to be uploaded to the respective S3 bucket for each environment.
- **Bucket path sample:**
	- Certificates for service `ai-auth-service` in environment `sit` are uploaded to:
	- `s3://ai-auth-service-sit-certs/`
- The pipeline syncs these certificates and appends them to Helm values for deployment.

### `ssm-config/`
- Contains configuration files to be uploaded to AWS SSM Parameter Store.
- **Parameter Store path:**
	- Each config is uploaded under `/service_name/key` for each environment.
	- Example: `ssm-config/ai-auth-service/sit/app_config.yaml` → `/ai-auth-service/app_config` in SSM Parameter Store.

### `values/`
- Contains Helm values files for each service and environment.
- Structure:
	- `values/<service>/<environment>/service/values.yaml` — Values for service chart
- The pipeline injects secrets, configs, and certificates into these values before deployment.

---
## How the Pipeline Works
1. **Reads environment config** from `env/` to determine cluster and role requirements.
2. **Uploads secrets** from `secrets/` to AWS Secrets Manager.
3. **Uploads configs** from `ssm-config/` to AWS SSM Parameter Store.
4. **Uploads SSL certificates** from `ssl-cert/` to the appropriate S3 bucket.
5. **Prepares Helm values** in `values/` by injecting secrets, configs, and certificates.
6. **Deploys service and ingress** using Helm charts from `helm/`, based on the environment configuration.

---
## Example Paths
- **Secrets Manager:** `ai-auth-service_tls_cert`, `ai-auth-service_db_password`
- **SSM Parameter Store:** `/ai-auth-service/app_config`, `/ai-auth-service/feature_flag`
- **S3 Bucket for SSL:** `s3://ai-auth-service-sit-certs/`
- **Helm Values:** `values/ai-auth-service/sit/values.yaml`

---
## Notes
- All configuration and secret files should be environment-specific.
- The pipeline automates secret/config/cert upload and Helm deployment based on these files.
- Ensure naming conventions match between local files and AWS resources for seamless integration.

---
For further details, see the workflow files in `.github/workflows/`.
# mibapp-workflow-repo
