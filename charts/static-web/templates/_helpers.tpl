{{- define "static-web.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "static-web.labels" -}}
app.kubernetes.io/name: {{ include "static-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/part-of: nothingeats
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "static-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "static-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
