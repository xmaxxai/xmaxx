# XMAXX Home

`home/` contains the first public application for XMAXX: the `xmaxx.ai` landing experience.

This is not treated as a throwaway startup template. It is the first product surface for a company that intends to combine AI, software, and hardware to improve real-world systems.

## Purpose

The home page should establish a clear position:

- XMAXX is building systems, not just content
- the company cares about performance and design quality
- the product direction spans digital and physical environments
- AI is used as an operational tool, not as decoration

In practical terms, the site should help explain how XMAXX intends to "maxx" systems across areas such as:

- water
- air
- environments
- equipment
- operations
- presentation and aesthetics
- software-driven control layers

## Frontend Stack

- React
- Vite
- CSS authored in-repo
- `nginx` for container runtime
- Docker for image packaging
- Helm for Kubernetes deployment
- Traefik ingress with Let’s Encrypt ACME

## Design Direction

The visual direction for `xmaxx.ai` should stay aligned with the product thesis:

- bold, not generic
- precise, not cluttered
- premium, not ornamental
- modern, not trend-chasing
- technical, not cold

The page should feel credible to:

- partners
- vendors
- customers
- employees
- operators

## Local Development

Install dependencies:

```bash
npm install
```

Start the dev server:

```bash
npm run dev
```

Build the production bundle:

```bash
npm run build
```

## Container Build

Build the image locally:

```bash
docker build -t home:local .
```

Release images must be published as multi-architecture manifests so both local ARM machines and amd64 cluster nodes can pull the same tag safely.

Build and push the release image:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --provenance=false \
  --sbom=false \
  -t <registry-user>/home:latest \
  --push .
```

Do not publish an ARM-only tag for production rollout. The cluster will fail to pull it with `no match for platform in manifest`.

## Kubernetes Release

The Helm chart lives in `home/chart/`.

Render the chart:

```bash
helm template home ./chart
```

Deploy or upgrade the release:

```bash
KUBECONFIG=<path-to-kubeconfig> helm upgrade --install home ./chart --namespace home --create-namespace
```

## Runtime Behavior

Current runtime model:

- namespace: `home`
- replicas: `2`
- ingress host: `xmaxx.ai`
- TLS: Traefik ACME resolver `letsencrypt`
- service port: `80`

The application is intended to be one public surface in a larger XMAXX platform, not the whole platform. As new services appear, `home` should remain the narrative entry point and the clearest expression of the company’s product direction.
