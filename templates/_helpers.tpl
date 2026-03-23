{{/*
Expand the name of the chart.
*/}}
{{- define "insurance-chat-assistant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "insurance-chat-assistant.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version label.
*/}}
{{- define "insurance-chat-assistant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "insurance-chat-assistant.labels" -}}
helm.sh/chart: {{ include "insurance-chat-assistant.chart" . }}
{{ include "insurance-chat-assistant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "insurance-chat-assistant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "insurance-chat-assistant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Build the full image reference: repository:tag
*/}}
{{- define "insurance-chat-assistant.image" -}}
{{- printf "%s:%s" .repository .tag }}
{{- end }}

{{/*
OpenShift-safe pod security context.
On OpenShift the SCC assigns the UID automatically — never set runAsUser.
*/}}
{{- define "insurance-chat-assistant.podSecurityContext" -}}
{{- if eq .Values.platform.type "openshift" }}
securityContext: {}
{{- else }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
OpenShift-safe container security context.
*/}}
{{- define "insurance-chat-assistant.securityContext" -}}
{{- if eq .Values.platform.type "openshift" }}
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
{{- else }}
securityContext:
  {{- toYaml .Values.securityContext | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Storage class helper
*/}}
{{- define "insurance-chat-assistant.storageClass" -}}
{{- if .Values.persistence.storageClass }}
storageClassName: {{ .Values.persistence.storageClass | quote }}
{{- end }}
{{- end }}

{{/*
Secret name for API keys
*/}}
{{- define "insurance-chat-assistant.secretName" -}}
{{- printf "%s-api-keys" (include "insurance-chat-assistant.fullname" .) }}
{{- end }}

{{/*
Postgres secret name
*/}}
{{- define "insurance-chat-assistant.postgresSecretName" -}}
{{- printf "%s-postgres" (include "insurance-chat-assistant.fullname" .) }}
{{- end }}