# PostgreSQL on EKS

This directory contains the Kubernetes manifests for a production-style PostgreSQL deployment that expects:

- AWS EKS or another Kubernetes cluster with the Amazon EBS CSI driver installed
- an internal-only namespace named `database`
- durable `gp3` EBS storage for live database files

Important repo context:

- the current checked-in infrastructure is still K3s on EC2, not EKS
- the live cluster reachable from `xmaxx-infra/kubeconfig.yaml` only has the `local-path` StorageClass today
- because there is no `ebs.csi.aws.com` driver in that cluster yet, an actual EBS-backed PVC would stay `Pending` there

## Apply

Create the namespace:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl create namespace database --dry-run=client -o yaml | KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl apply -f -
```

Load the repo-local `.env` values so the Secret picks up `POSTGRES_PASSWORD` without committing it in plain text:

```bash
set -a
source .env
set +a
```

Apply the manifests:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl apply -f xmaxx-infra/k8s/postgres/01-storageclass.yaml
envsubst < xmaxx-infra/k8s/postgres/02-secret.yaml | KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl apply -f -
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl apply -f xmaxx-infra/k8s/postgres/03-service.yaml
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl apply -f xmaxx-infra/k8s/postgres/04-statefulset.yaml
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl apply -f xmaxx-infra/k8s/postgres/05-pdb.yaml
```

## Verify

Check that the PVC is bound and the pod is healthy:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n database get pvc,pod,svc,pdb
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n database describe pvc postgres-data-postgres-0
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n database rollout status statefulset/postgres
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n database exec postgres-0 -- pg_isready -U appuser -d appdb
```

If the cluster does not have the EBS CSI driver installed, `postgres-data-postgres-0` will remain `Pending`.

## Backup Guidance

### Logical backups with `pg_dump`

Use a CronJob or external automation that:

- authenticates to AWS with IRSA or another non-static credential flow
- runs `pg_dump -Fc` against `appdb`
- pushes the resulting dump file into a versioned S3 bucket

Example pattern:

```bash
KUBECONFIG=xmaxx-infra/kubeconfig.yaml kubectl -n database exec postgres-0 -- sh -lc 'export PGPASSWORD="$POSTGRES_PASSWORD"; pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' | aws s3 cp - s3://<bucket>/postgres/logical/appdb-$(date +%F).dump
```

### WAL archiving to S3

For point-in-time recovery, do not rely on `pg_dump` alone. Enable WAL archiving and push WAL segments to S3 with `wal-g` or an equivalent tool:

- set `wal_level=replica`
- set `archive_mode=on`
- set `archive_timeout=60s`
- set `archive_command` to a tested S3 upload command, typically through `wal-g wal-push %p`

Recommended production pattern:

- use a custom Postgres image or sidecar that includes `wal-g`
- mount S3 credentials through IRSA rather than static access keys
- restore by replaying WAL from S3 onto a fresh EBS-backed volume

## Why EBS for Live Data and S3 for Backups

Use EBS for active Postgres data because PostgreSQL needs low-latency block storage with filesystem semantics, write ordering, and predictable IOPS.

Use S3 only for backups because it is object storage, not a live database filesystem. It is excellent for durable backup retention, WAL archives, and disaster recovery copies, but it is the wrong place to mount `PGDATA` for a running PostgreSQL server.
