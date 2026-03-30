# XMAXX

XMAXX is the codebase for the initial XMAXX platform footprint: AWS infrastructure, a K3s cluster, an app delivery path built around Docker and Helm, and the `xmaxx.ai` home experience built in React.

The repo is intentionally managed as code first:

- Infrastructure is described in Terraform.
- Cluster ingress and certificate behavior are described in Kubernetes and Helm configuration.
- The frontend is built as a container and deployed through the cluster.
- Sensitive runtime material such as kubeconfigs, Terraform state, and private variables are excluded from Git.

## Repository Layout

- `home/`: React frontend, Docker image definition, and Helm chart for the `home` application.
- `xmaxx-infra/`: Terraform for the base AWS network, K3s control plane node, API load balancer path, and Traefik configuration manifests.
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

## Security Note

The repository is designed to avoid committing:

- kubeconfigs
- Terraform state
- `terraform.tfvars`
- private keys, PEM files, and certificate files
- local dependency and build artifacts

That policy is enforced by the repo-root `.gitignore`.
