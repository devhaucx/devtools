{{/*
Expand the name of the chart.
*/}}
{{- define "azure-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "azure-agent.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "azure-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "azure-agent.selectorLabels" -}}
app: {{ include "azure-agent.fullname" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "azure-agent.labels" -}}
helm.sh/chart: {{ include "azure-agent.chart" . }}
{{ include "azure-agent.selectorLabels" . }}
app.kubernetes.io/name: {{ include "azure-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use for the agent pod
*/}}
{{- define "azure-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "azure-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "admin" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the secret name for agent credentials (URL, Token, Pool)
*/}}
{{- define "azure-agent.secretName" -}}
{{- default "azure-agent-secret" .Values.secret.name -}}
{{- end }}

{{/*
Return the proper agent image name
*/}}
{{- define "azure-agent.image" -}}
{{- $registryName := default .Values.agent.image.registry (and .Values.global .Values.global.imageRegistry) -}}
{{- $repositoryName := .Values.agent.image.repository -}}
{{- $tag := .Values.agent.image.tag | default .Chart.AppVersion | toString -}}
{{- if $registryName }}
    {{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
    {{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }}

{{/*
Return the proper image pull secrets (supports global.imagePullSecrets and imagePullSecrets)
*/}}
{{- define "azure-agent.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- if and .Values.global .Values.global.imagePullSecrets }}
  {{- range .Values.global.imagePullSecrets }}
    {{- if kindIs "map" . }}
      {{- $pullSecrets = append $pullSecrets .name }}
    {{- else }}
      {{- $pullSecrets = append $pullSecrets . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.imagePullSecrets }}
  {{- range .Values.imagePullSecrets }}
    {{- if kindIs "map" . }}
      {{- $pullSecrets = append $pullSecrets .name }}
    {{- else }}
      {{- $pullSecrets = append $pullSecrets . }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
  {{- range ($pullSecrets | uniq) }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
