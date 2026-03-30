# Infrastructure and Operations

## Purpose

This document explains how the repository maps to the deployed system and how to operate the current platform without relying on undocumented manual steps.

## Repository Responsibilities

### `xmaxx-infra/`

Owns the base AWS and control-plane layer.

Key concerns:

- VPC and subnet layout
- internet gateway and route tables
- K3s server instance
- K3s API ingress path
- Traefik Helm configuration for ACME and persistent certificate storage

Notable files:

- `xmaxx-infra/main.tf`
- `xmaxx-infra/imports.tf`
- `xmaxx-infra/k8s/traefik/helmchartconfig.yaml`

### `xmaxx-infra-workers/`

Owns worker capacity and app-facing network entry.

Key concerns:

- worker node instances
- worker security group
- app-facing AWS Network Load Balancer
- target groups and listeners for `80` and `443`

Notable files:

- `xmaxx-infra-workers/main.tf`
- `xmaxx-infra-workers/terraform.tfvars.example`

### `home/`

Owns the frontend application and its deployable package.

Key concerns:

- React code
- Docker build
- Helm chart
- ingress and release behavior

Notable files:

- `home/src/`
- `home/Dockerfile`
- `home/nginx.conf`
- `home/chart/`

## Deployment Model

### Terraform

Terraform is the source of truth for:

- AWS network layout
- EC2 instances
- load balancers
- core security groups

Operational rule:

- do not commit plain-text `terraform.tfvars`
- do not commit Terraform state
- do commit `.terraform.lock.hcl`

### Docker

The `home` application is built into a container image and published to Docker Hub.

Operational rule:

- publish an architecture-compatible image for the cluster nodes
- keep image tags intentional
- avoid depending on untracked local artifacts

### Helm

Helm manages the `home` release into K3s.

Operational rule:

- application deployment behavior belongs in the chart
- ingress behavior belongs in the chart unless it is truly platform-wide
- platform-wide Traefik behavior belongs in the Traefik HelmChartConfig

### React Frontend

The frontend is not being treated as a disposable landing page template. It is the first product surface and should be handled as an evolving interface system.

Operational rule:

- design updates should preserve performance and deployability
- the public page should remain legible, fast, and intentional on desktop and mobile
- avoid turning the site into generic startup filler

## Certificate and HTTPS Model

The active HTTPS path is:

- Traefik ingress controller
- Let’s Encrypt ACME
- HTTP-01 challenge
- PVC-backed `/data/acme.json`

Why the PVC matters:

- cert state survives Traefik rollout and node restart scenarios
- the cluster does not have to reissue certificates on every controller change
- TLS becomes part of the platform runtime, not an ephemeral side effect

## Operational Commands

Use these as patterns, not as a place to store secrets.

### Validate Terraform

```bash
terraform -chdir=xmaxx-infra validate
terraform -chdir=xmaxx-infra-workers validate
```

### Build the Frontend

```bash
cd home
npm install
npm run build
```

### Build and Push the Container

```bash
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  -t <registry-user>/home:latest \
  --push ./home
```

### Render or Upgrade the Helm Release

```bash
helm template home ./home/chart
KUBECONFIG=<path-to-kubeconfig> helm upgrade --install home ./home/chart --namespace home --create-namespace
```

### Inspect the Live App

```bash
KUBECONFIG=<path-to-kubeconfig> kubectl get pods,svc,ingress -n home
curl -I http://xmaxx.ai
curl -I https://xmaxx.ai
```

## Security Rules

The repository should never contain plain-text:

- kubeconfigs
- Terraform state
- `terraform.tfvars`
- live cluster tokens
- private keys or PEM material

That is why the repo-root `.gitignore` blocks those files by default.

Exception:

- `xmaxx-infra-workers/terraform.tfvars`
- `xmaxx-infra/kubeconfig.yaml`

Those two files may be committed only when `git-crypt` is initialized and the files are encrypted in Git. See `documentation/git-crypt.md`.

## Change Management Guidance

When making platform changes:

1. Update the code first.
2. Validate locally.
3. Apply or deploy deliberately.
4. Update documentation in the same change set.
5. Avoid one-off console edits unless they are captured back into code immediately.

## Recommended Next Operations

- add a staging environment
- add cluster observability and alerting
- formalize image tagging and release promotion
- add backup and restore procedures for critical cluster state
- decide how future services beyond `home` will be charted and released
