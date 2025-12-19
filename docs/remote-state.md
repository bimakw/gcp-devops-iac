# Terraform Remote State Management

This document describes how to set up and use GCS (Google Cloud Storage) backend for Terraform remote state.

## Overview

Remote state storage provides:
- **Team Collaboration**: Multiple team members can work on the same infrastructure
- **State Locking**: Prevents concurrent modifications that could corrupt state
- **Versioning**: Track state changes and rollback if needed
- **Security**: Centralized access control and encryption

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GCS State Bucket                          │
│          ${PROJECT_ID}-terraform-state                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  terraform/state/                                            │
│  ├── dev/                                                    │
│  │   └── default.tfstate                                     │
│  ├── staging/                                                │
│  │   └── default.tfstate                                     │
│  └── prod/                                                   │
│      └── default.tfstate                                     │
│                                                              │
│  Features:                                                   │
│  ├── Versioning enabled (5 versions retained)               │
│  ├── Uniform bucket-level access                            │
│  └── Encryption at rest (Google-managed keys)               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Bootstrap the Backend

Run the bootstrap script to create the GCS bucket:

```bash
# For development environment
./scripts/bootstrap-backend.sh -p YOUR_PROJECT_ID -e dev

# For staging environment
./scripts/bootstrap-backend.sh -p YOUR_PROJECT_ID -e staging

# For production environment
./scripts/bootstrap-backend.sh -p YOUR_PROJECT_ID -e prod
```

### 2. Initialize Terraform

Navigate to the environment directory and initialize:

```bash
cd terraform/environments/dev
terraform init
```

If migrating from local state:

```bash
terraform init -migrate-state
```

## Backend Configuration

Each environment has its own backend configuration:

### Development (`terraform/environments/dev/backend.tf`)

```hcl
terraform {
  backend "gcs" {
    bucket = "your-project-terraform-state"
    prefix = "terraform/state/dev"
  }
}
```

### Staging (`terraform/environments/staging/backend.tf`)

```hcl
terraform {
  backend "gcs" {
    bucket = "your-project-terraform-state"
    prefix = "terraform/state/staging"
  }
}
```

### Production (`terraform/environments/prod/backend.tf`)

```hcl
terraform {
  backend "gcs" {
    bucket = "your-project-terraform-state"
    prefix = "terraform/state/prod"
  }
}
```

## State Locking

GCS backend automatically handles state locking using object generation numbers. When a Terraform operation begins:

1. Terraform reads the current state
2. Before writing, it checks if the generation number matches
3. If another process modified the state, the operation fails
4. This prevents race conditions and state corruption

No additional configuration is required for state locking.

## Security Best Practices

### IAM Permissions

Required permissions for Terraform users:

```yaml
roles/storage.objectAdmin:  # For state read/write
  - storage.objects.create
  - storage.objects.delete
  - storage.objects.get
  - storage.objects.list
  - storage.objects.update

roles/storage.bucketReader:  # For bucket access
  - storage.buckets.get
```

### Recommended IAM Setup

```hcl
# Grant access to Terraform service account
resource "google_storage_bucket_iam_member" "terraform_state" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:terraform@${var.project_id}.iam.gserviceaccount.com"
}
```

### Customer-Managed Encryption Keys (CMEK)

For additional security, use CMEK:

```hcl
terraform {
  backend "gcs" {
    bucket         = "your-project-terraform-state"
    prefix         = "terraform/state/prod"
    encryption_key = "your-base64-encoded-key"
  }
}
```

Or set the environment variable:

```bash
export GOOGLE_ENCRYPTION_KEY="your-base64-encoded-key"
terraform init
```

## Operations

### View Current State

```bash
# List state file versions
gsutil ls -la gs://your-project-terraform-state/terraform/state/dev/

# Download state for inspection (be careful!)
gsutil cp gs://your-project-terraform-state/terraform/state/dev/default.tfstate ./state-backup.json
```

### Recover from State Corruption

```bash
# List available versions
gsutil ls -a gs://your-project-terraform-state/terraform/state/dev/

# Restore specific version
gsutil cp gs://your-project-terraform-state/terraform/state/dev/default.tfstate#1234567890 \
          gs://your-project-terraform-state/terraform/state/dev/default.tfstate
```

### Force Unlock State

If a Terraform operation fails and leaves the state locked:

```bash
# GCS backend doesn't require manual unlock
# Simply retry the operation
terraform plan
```

## CI/CD Integration

### Cloud Build

```yaml
steps:
  - id: 'terraform-init'
    name: 'hashicorp/terraform:1.5'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        cd terraform/environments/${_ENVIRONMENT}
        terraform init

  - id: 'terraform-plan'
    name: 'hashicorp/terraform:1.5'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        cd terraform/environments/${_ENVIRONMENT}
        terraform plan -out=tfplan

  - id: 'terraform-apply'
    name: 'hashicorp/terraform:1.5'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        cd terraform/environments/${_ENVIRONMENT}
        terraform apply -auto-approve tfplan
```

### GitHub Actions

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/environments/dev

      - name: Terraform Plan
        run: terraform plan
        working-directory: terraform/environments/dev
```

## Troubleshooting

### "Error acquiring the state lock"

This typically means another process is running. Wait for it to complete or verify no other operations are in progress.

### "Backend configuration changed"

Run `terraform init -reconfigure` to reinitialize with new backend settings.

### "Error loading state"

Check:
1. Bucket exists and is accessible
2. IAM permissions are correct
3. Network connectivity to GCS

## References

- [Terraform GCS Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [GCS Security Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)
