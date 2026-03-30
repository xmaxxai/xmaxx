<p align="center">
  <img src="./logo.png" alt="XMAXX logo" width="220">
</p>

# XMAXX

XMAXX is the codebase for the initial XMAXX platform footprint: AWS infrastructure, a K3s cluster, an app delivery path built around Docker and Helm, and the `xmaxx.ai` home experience built in React.

The repo is intentionally managed as code first:

- Infrastructure is described in Terraform.
- Cluster ingress and certificate behavior are described in Kubernetes and Helm configuration.
- The frontend is built as a container and deployed through the cluster.
- Sensitive runtime material is either excluded from Git or committed only through `git-crypt`.

## Repository Layout

- `home/`: React frontend, Docker image definition, and Helm chart for the `home` application.
- `home-backend/`: Django backend scaffold, Docker image definition, and PostgreSQL-backed runtime settings for the `home` application.
- `xmaxx-infra/`: Terraform for the base AWS network, K3s control plane node, API load balancer path, and Traefik configuration manifests.
- `xmaxx-infra/k8s/postgres/`: EKS-oriented PostgreSQL manifests using a StatefulSet, EBS-backed storage, and operational guidance.
- `xmaxx-infra-workers/`: Terraform for worker nodes and the app-facing network load balancer.
- `documentation/`: architecture, operations, product, and audience-facing documentation.

## Current Platform Shape

- AWS region: `us-east-2`
- Kubernetes distribution: `K3s`
- Frontend runtime: `React + Vite`, served by `nginx`
- Container registry: Docker Hub
- Release path: Helm on K3s
- Public app domain: `xmaxx.ai`
- Public control-plane domain: `k3s-api.xmaxx.ai`

## Documentation

Start here:

- `documentation/README.md`
- `documentation/platform-architecture.md`
- `documentation/infrastructure-and-operations.md`
- `documentation/product-and-audiences.md`
- `home-backend/README.md`

## App Config Notes

The `home-backend` GitHub OAuth secret can be supplied either as a direct env var or as a mounted file. In Kubernetes, the Helm chart mounts the secret file into the backend pod at `/var/run/secrets/github/oauth/client-secret`.

Important constraint:

- that mounted file must contain the raw GitHub OAuth client secret string
- a PEM or certificate file is not a valid GitHub OAuth client secret

The detailed app config and deploy-time secret guidance lives in `home-backend/README.md`.

## Security Note

The repository is designed to avoid committing plain-text:

- kubeconfigs
- Terraform state
- `terraform.tfvars`
- private keys, PEM files, and certificate files
- local dependency and build artifacts

That policy is enforced by the repo-root `.gitignore`.

Two paths are explicitly approved for encrypted storage through `git-crypt`:

- `xmaxx-infra-workers/terraform.tfvars`
- `xmaxx-infra/kubeconfig.yaml`

Bootstrap and collaborator access steps are documented in `documentation/git-crypt.md`.
