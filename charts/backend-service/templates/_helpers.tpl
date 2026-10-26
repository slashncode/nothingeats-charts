{{- define "backend-service.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "backend-service.labels" -}}
app.kubernetes.io/name: {{ include "backend-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/part-of: nothingeats
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "backend-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backend-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "backend-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "backend-service.name" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "backend-service.image" -}}
{{- required "image.tag is required" .Values.image.tag | printf "%s:%s" .Values.image.repository -}}
{{- end -}}

{{/* Environment shared by the Deployment, the migrate Job and the CronJobs. */}}
{{- define "backend-service.env" -}}
{{- range $name, $value := .Values.env }}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end }}
{{- range $name, $ref := .Values.secretEnv }}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ required (printf "secretEnv.%s.secret is required" $name) $ref.secret }}
      key: {{ required (printf "secretEnv.%s.key is required" $name) $ref.key }}
{{- end }}
{{- end -}}

{{/* Restricted pod security: non-root, read-only root filesystem, no privilege escalation. */}}
{{- define "backend-service.containerSecurityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
runAsNonRoot: true
runAsUser: 65532
runAsGroup: 65532
capabilities:
  drop: ["ALL"]
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{/* One container spec for every workload kind; only the arguments differ. */}}
{{- define "backend-service.container" -}}
image: {{ include "backend-service.image" .root }}
imagePullPolicy: {{ .root.Values.image.pullPolicy }}
{{- with .args }}
args:
  {{- toYaml . | nindent 2 }}
{{- end }}
env:
  - name: HTTP__PORT
    value: {{ .root.Values.containerPort | quote }}
  {{- if .root.Values.grpc.enabled }}
  - name: GRPC__PORT
    value: {{ .root.Values.grpc.port | quote }}
  {{- end }}
  {{- include "backend-service.env" .root | nindent 2 }}
{{- with .root.Values.envFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
securityContext:
  {{- include "backend-service.containerSecurityContext" . | nindent 2 }}
volumeMounts:
  - name: tmp
    mountPath: /tmp
{{- end -}}
