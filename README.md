<p align="center">
  <img src="https://raw.githubusercontent.com/xmaxxai/xmaxx/main/logo.png" alt="XMAXX logo" >
</p>

# XMAXX

XMAXX is the codebase for the initial XMAXX platform footprint: AWS infrastructure, a K3s cluster, an app delivery path built around Docker and Helm, and the `xmaxx.ai` home experience built in React.

Public links:

- Website: `https://xmaxx.ai`
- X: `https://x.com/xmaxxai` (`@xmaxxai`)

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
- Container registry: Amazon ECR
- Release path: Helm on K3s
- Public app domain: `xmaxx.ai`
- Public control-plane domain: `k3s-api.xmaxx.ai`

## Container Images

The published Docker tags for `home` and `home-backend` should be multi-architecture manifests in Amazon ECR, not single-architecture images.

Current requirement:

- publish `linux/amd64,linux/arm64`
- do not push ARM-only tags for releases that the cluster will consume
- keep the mutable tags such as `latest` and `backend-latest` multi-arch as well, not just the versioned tags

Recommended release pattern:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t 351381968847.dkr.ecr.us-east-2.amazonaws.com/xmaxx/home:<tag> \
  --push <context>
```

Reason:

- the live K3s nodes are not guaranteed to match local development architecture
- Macs used for development may be `arm64` while cluster nodes often pull `amd64`
- a multi-arch manifest avoids `no match for platform in manifest` pull failures during rollout

## Documentation

Start here:

- `documentation/README.md`
- `documentation/platform-architecture.md`
- `documentation/infrastructure-and-operations.md`
- `documentation/product-and-audiences.md`
- `home-backend/README.md`

## App Config Notes

The `home-backend` OAuth secrets are supplied through the Kubernetes secret/env path:

- `GITHUB_OAUTH_CLIENT_SECRET`
- `GOOGLE_OAUTH_CLIENT_SECRET`

Important constraint:

- `GITHUB_OAUTH_CLIENT_SECRET` must be the raw GitHub OAuth client secret value
- `GOOGLE_OAUTH_CLIENT_SECRET` must be the raw Google OAuth client secret value
- a PEM or certificate file is not a valid GitHub OAuth client secret

The deployed frontend now opens a provider chooser modal and completes OAuth in a popup while the Django backend handles the callback flow on the same `xmaxx.ai` origin.

The detailed app config and deploy-time secret guidance lives in `home-backend/README.md`.

## CI/CD

Application images are now intended to flow through GitHub Actions into Amazon ECR:

- workflow: `.github/workflows/build-and-push-ecr.yml`
- AWS auth model: GitHub OIDC into the `xmaxx-github-actions-ecr-push` role
- frontend image: `351381968847.dkr.ecr.us-east-2.amazonaws.com/xmaxx/home`
- backend image: `351381968847.dkr.ecr.us-east-2.amazonaws.com/xmaxx/home-backend`

The K3s EC2 nodes pull from private ECR through the Terraform-managed instance profile `xmaxx-k3s-node-ecr-pull`.

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
