#!/usr/bin/env bash
# Lints every chart and validates the rendered manifests against the Kubernetes and Gateway API schemas.
# Each chart is rendered with its ci-values.yaml so every optional template is covered.
set -euo pipefail

cd "$(dirname "$0")/.."
k8s_version="${K8S_VERSION:-1.36.0}"

for chart in charts/*/; do
    values="$chart/ci-values.yaml"
    echo "== $(basename "$chart")"
    helm lint --strict "$chart" -f "$values"
    helm template ci "$chart" -f "$values" |
        kubeconform -strict -summary \
            -kubernetes-version "$k8s_version" \
            -schema-location default \
            -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
done

# Flux appends the OCI digest to the chart version (0.1.0+<digest>); labels must stay valid with it.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
for chart in charts/*/; do
    helm package "$chart" --version 0.0.0+ci0123456789 --destination "$work" >/dev/null
    rendered=$(helm template ci "$work/$(basename "$chart")-0.0.0+ci0123456789.tgz" -f "$chart/ci-values.yaml")
    if grep -qE '^\s+[a-z0-9./-]+: .*\+' <<<"$(grep -A20 'labels:' <<<"$rendered")"; then
        echo "::error::$(basename "$chart"): a label contains '+' when the chart version has build metadata"
        exit 1
    fi
done

