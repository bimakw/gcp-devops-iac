# GCP DevOps IaC

Production-ready GCP infrastructure with Terraform. Includes GKE, Cloud SQL (PostgreSQL), Memorystore (Redis), Cloud Armor, Artifact Registry, Cloud Build CI/CD, Secret Manager, and monitoring.

## Quick Start

```bash
cd terraform/environments/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

Then configure kubectl and deploy K8s components:

```bash
gcloud container clusters get-credentials <cluster> --region <region>
kubectl apply -k kubernetes/argocd/
kubectl apply -k kubernetes/prometheus/
```

## What's Included

**Terraform modules**: networking, GKE, Cloud SQL, Memorystore, Cloud Armor (WAF), Artifact Registry, Cloud Build, monitoring, secrets, Velero backup, cost management

**Kubernetes**: ArgoCD, Prometheus, Grafana, Istio, cert-manager, external-secrets, OPA Gatekeeper, sealed-secrets, Velero

**Environments**: dev, staging, prod with size-appropriate resources

## License

MIT with attribution — see [LICENSE](LICENSE).
