# nothingeats-charts

Helm charts for [NothingEats](https://github.com/slashncode/nothingeats), published as signed OCI artifacts to `oci://ghcr.io/slashncode/charts`.

## `backend-service`

One chart for every backend service (Kotlin and TypeScript):

- **Deployment** running `serve`, with startup, liveness and readiness probes on `/health/*`, a restricted security context (non-root UID 65532, read-only root filesystem with an `emptyDir` for `/tmp`, no capabilities) and no service-account token.
- **Migrate Job** as a Helm `pre-install,pre-upgrade` hook running `migrate`. Pods never migrate on start and refuse to serve against a schema with pending migrations, so a failed migration stops the rollout instead of breaking it.
- **CronJobs** running `cron <task>` from `cronJobs: [{name, task, schedule}]`.
- **HTTPRoute** (Gateway API) for `/api/<context>`, derived from the release name (`catalog-service` → `/api/catalog`).
- Optional **PodDisruptionBudget**.

```yaml
image:
  repository: ghcr.io/slashncode/nothingeats-catalog-service
  tag: main-1a2b3c4-1761300000
env:
  DATABASE__URL: jdbc:postgresql://postgres-rw:5432/catalog
secretEnv:
  DATABASE__USER: { secret: catalog-db, key: username }
  DATABASE__PASSWORD: { secret: catalog-db, key: password }
route:
  enabled: true
```

See [`values.yaml`](charts/backend-service/values.yaml) for everything else.

## `static-web`

One chart for every single-page app (web, backoffice), built into an nginx-unprivileged image:

- **Deployment** with liveness and readiness probes on `/healthz`, the same restricted security context (UID 101 of nginx-unprivileged, read-only root filesystem, `/tmp` as `emptyDir`), no service-account token.
- **Runtime configuration** through `env` / `secretEnv`: the image writes them into `/env.js` at start, so one image serves every environment.
- **HTTPRoute** for `/` by default; Gateway API picks the most specific path, so `/api/*` still reaches the services.
- Optional **PodDisruptionBudget**.

```yaml
image:
  repository: ghcr.io/slashncode/nothingeats-web
  tag: main-1a2b3c4-1761300000
env:
  POSTHOG_HOST: https://eu.i.posthog.com
route:
  enabled: true
```

## Development

```bash
mise install          # helm, kubeconform, yq
scripts/validate.sh   # helm lint --strict + kubeconform against Kubernetes 1.36 and Gateway API schemas
```

Each chart has a `ci-values.yaml` that switches on every optional template for validation.

## Releases

CI publishes a chart when its `version` in `Chart.yaml` is not in the registry yet, then signs it with cosign (keyless). Pull requests that change a chart without bumping its version fail.

## License

MIT
