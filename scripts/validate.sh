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
