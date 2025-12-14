# Terraform Validation Pipeline

Automated CI/CD pipeline untuk validasi Terraform code sebelum deployment.

## Pipeline Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  terraform  │───▶│  terraform  │───▶│   tflint    │───▶│   tfsec     │
│     fmt     │    │   validate  │    │  (linting)  │    │ (security)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                             │                  │
                                             ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  infracost  │◀───│  terraform  │◀───│   checkov   │◀───┘
│   (cost)    │    │    plan     │    │  (policy)   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Pipeline Steps

### 1. Terraform Format Check
```bash
terraform fmt -check -recursive -diff terraform/
```
- Ensures consistent code formatting
- Fails if any file needs formatting
- Run `terraform fmt -recursive terraform/` to fix

### 2. Terraform Init & Validate
```bash
terraform init -backend=false
terraform validate
```
- Initializes Terraform (without backend for validation)
- Validates syntax and configuration

### 3. TFLint - Best Practices
```bash
tflint --init --config=.tflint.hcl
tflint --recursive --config=.tflint.hcl terraform/
```
- Checks for best practices violations
- Validates GCP-specific rules
- Enforces naming conventions
- Configuration: `.tflint.hcl`

### 4. TFSec - Security Scanner
```bash
tfsec terraform/ --format=compact
```
- Scans for security misconfigurations
- Checks GCP security best practices
- Identifies potential vulnerabilities
- Configuration: `.tfsec/config.yml`

### 5. Checkov - Policy Compliance
```bash
checkov -d terraform/ --framework terraform
```
- Policy-as-code compliance checking
- 500+ built-in policies
- CIS Benchmark validation
- Configuration: `.checkov.yml`

### 6. Terraform Plan
```bash
terraform plan -out=tfplan
```
- Generates execution plan
- Shows what will be created/modified/destroyed
- Requires GCP credentials

### 7. Infracost - Cost Estimation
```bash
infracost breakdown --path terraform/
```
- Estimates monthly costs
- Shows cost diff vs current
- Requires Infracost API key (free tier available)

## Trigger Configuration

### Automatic Trigger on PR
```bash
gcloud builds triggers create github \
  --name="terraform-validate" \
  --repo-name="gcp-devops-iac" \
  --repo-owner="bimakw" \
  --branch-pattern="^feature/.*$" \
  --included-files="terraform/**" \
  --build-config="cloudbuild/cloudbuild-terraform.yaml"
```

### Manual Trigger
```bash
gcloud builds submit \
  --config=cloudbuild/cloudbuild-terraform.yaml \
  --substitutions=_ENVIRONMENT=dev
```

## Required Secrets

Create these secrets in Secret Manager:

```bash
# GCP Project ID for Terraform
echo -n "your-project-id" | gcloud secrets create terraform-project-id --data-file=-

# Infracost API Key (optional, get free key at infracost.io)
echo -n "your-infracost-api-key" | gcloud secrets create infracost-api-key --data-file=-
```

## Local Development

### Run Validation Locally

```bash
# Format check
terraform fmt -check -recursive terraform/

# Init and validate
cd terraform/environments/dev
terraform init -backend=false
terraform validate
cd ../../..

# TFLint
docker run --rm -v $(pwd):/data -w /data \
  ghcr.io/terraform-linters/tflint:v0.50.0 \
  --init --config=.tflint.hcl && \
  tflint --recursive --config=.tflint.hcl terraform/

# TFSec
docker run --rm -v $(pwd):/src \
  aquasec/tfsec /src/terraform

# Checkov
docker run --rm -v $(pwd):/tf \
  bridgecrew/checkov -d /tf/terraform
```

## Customization

### Skip Specific Checks

**TFLint** - Edit `.tflint.hcl`:
```hcl
rule "terraform_documented_variables" {
  enabled = false  # Disable this rule
}
```

**TFSec** - Edit `.tfsec/config.yml`:
```yaml
exclude:
  - google-gke-use-rbac-permissions
```

**Checkov** - Edit `.checkov.yml`:
```yaml
skip-check:
  - CKV_GCP_12  # VPC Flow Logs
```

### Inline Suppressions

**TFSec** - Add comment in `.tf` file:
```hcl
resource "google_compute_instance" "example" {
  #tfsec:ignore:google-compute-no-public-ip
  network_interface {
    access_config {} # Public IP needed for this instance
  }
}
```

**Checkov** - Add comment in `.tf` file:
```hcl
resource "google_storage_bucket" "example" {
  #checkov:skip=CKV_GCP_62:Bucket logging not required for this use case
  name = "example-bucket"
}
```

## Best Practices

1. **Fix formatting first** - Always run `terraform fmt` before committing
2. **Address HIGH/CRITICAL issues** - Security issues should be fixed or documented
3. **Document suppressions** - Always explain why a check is skipped
4. **Review cost estimates** - Check Infracost output before applying changes
5. **Keep configs updated** - Update tool versions periodically
