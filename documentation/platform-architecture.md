# Platform Architecture

## Objective

The current XMAXX platform establishes a practical base for shipping the `xmaxx.ai` experience and evolving it into a larger AI-enabled software and hardware platform. The system is deliberately small, but every layer is already represented in code:

- AWS infrastructure
- Kubernetes runtime
- Docker image build and distribution
- Helm-based app deployment
- React frontend delivery
- HTTPS certificate automation

## Current Topology

### Region and Network

- Cloud: AWS
- Region: `us-east-2`
- VPC CIDR: `10.0.0.0/16`
- Public and private-style subnets are defined in Terraform under `xmaxx-infra/`

The current environment uses a single VPC with route tables, an internet gateway, and an S3 gateway endpoint. One subnet that was originally labeled private is currently associated with the public route table because the control-plane instance needs reachable public networking.

### Control Plane Stack

Managed in `xmaxx-infra/`.

Primary responsibilities:

- VPC, subnets, route tables, and security groups
- K3s server EC2 instance
- K3s API load balancer path
- Traefik configuration for ACME and persistent certificate storage

Current design notes:

- K3s is bootstrapped on an EC2 instance with Terraform-managed `user_data`
- The K3s server is the first control-plane node
- A dedicated API-facing AWS Network Load Balancer is used for cluster API access
- The control-plane hostname is intended to remain distinct from the application hostname

### Worker and App Delivery Stack

Managed in `xmaxx-infra-workers/`.

Primary responsibilities:

- K3s worker EC2 instances
- Worker security group rules
- Application-facing AWS Network Load Balancer on ports `80` and `443`

This creates a clean separation:

- `k3s-api.xmaxx.ai` for Kubernetes control-plane traffic
- `xmaxx.ai` for application traffic

### Application Stack

Managed in `home/`.

Primary responsibilities:

- React frontend source
- Docker image build definition
- Helm chart for Kubernetes deployment
- Service and ingress rules for public delivery

The `home` application is deployed as:

- a Docker image pushed to Docker Hub
- a Helm release into the `home` namespace
- a Kubernetes `Service`
- a Traefik-backed `Ingress`

## Traffic Flow

### End-User App Traffic

1. A user resolves `xmaxx.ai`.
2. DNS points to the app-facing AWS Network Load Balancer.
3. The load balancer forwards TCP `80/443` to cluster nodes.
4. Traefik receives the request inside K3s.
5. HTTP is redirected to HTTPS at the Traefik entrypoint.
6. HTTPS traffic is routed to the `home` service.
7. The `home` pods serve the React application through `nginx`.

### Control Plane Traffic

1. An operator or worker node resolves `k3s-api.xmaxx.ai`.
2. DNS points to the API Network Load Balancer.
3. The load balancer forwards TCP `6443` to the K3s server.
4. `kubectl` and worker joins terminate against the K3s API endpoint.

### Certificate Flow

TLS for `xmaxx.ai` is handled by Traefik using ACME:

- Let’s Encrypt HTTP-01 challenge
- Traefik resolver name: `letsencrypt`
- Persistent ACME storage: `/data/acme.json`
- Storage backing: a PVC named `traefik` in `kube-system`

This matters operationally because certificate state survives pod restarts and avoids unnecessary reissuance.

## Design Decisions

### Why K3s

K3s is a practical choice for the current stage:

- small operational footprint
- fast bootstrap on EC2
- easy progression from one node to multiple nodes
- enough Kubernetes surface area to support Helm, ingress, and future workloads

### Why Helm

Helm turns app deployment into a versioned, repeatable package:

- image reference
- replica count
- service behavior
- ingress rules
- TLS resolver selection

That makes `home` deployable without manual cluster edits.

### Why Docker Hub

Docker Hub provides a simple registry path for the current stage. The image is built locally, pushed to Docker Hub, and pulled by K3s nodes.

### Why React for the Home App

The home page is the first public product surface, not a throwaway page. React and Vite provide:

- fast iteration
- component-based UX development
- a clean path to richer motion and data-driven storytelling
- a straightforward production build pipeline

## Constraints and Next Steps

Current constraints:

- single control-plane node
- one worker stack
- app delivery is basic ingress and service routing, not a full platform release system
- no GitOps controller yet
- no separate staging environment yet

Likely next steps:

- add control-plane redundancy
- add staging and promotion workflows
- expand worker pools by workload type
- introduce observability and backup routines
- add additional product services behind the same ingress layer
