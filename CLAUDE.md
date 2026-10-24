# CLAUDE.md

Helm charts for NothingEats. The cross-repo plan and session rules live in `../CLAUDE.md` (workspace root), if present — read it first.

## Commands

- `scripts/validate.sh` — `helm lint --strict` + kubeconform (Kubernetes 1.36 + Gateway API CRD schemas) for every chart, rendered with its `ci-values.yaml`
- `helm template <release> charts/<chart> -f charts/<chart>/ci-values.yaml` — inspect output

## Rules

- Every change to a chart bumps its `version` in `Chart.yaml`; CI publishes only versions that are not in the registry yet.
- New optional templates must be switched on in `ci-values.yaml` so validation covers them.
- Keep the restricted security context (non-root 65532, read-only root FS, drop ALL, no SA token). Services that need more must say why.
- The Deployment, migrate Job and CronJobs share one container definition (`backend-service.container`); only `args` differ.
- Before changing behaviour, test it in the local k3d cluster: import an image with `k3d image import`, `helm install` into a throwaway namespace, check the hook Job and probes, delete the namespace.
