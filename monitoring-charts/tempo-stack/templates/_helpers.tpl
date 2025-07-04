{{/*
Expand the name of the chart.
*/}}
{{- define "tempo-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tempo-stack.fullname" -}}
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
{{- define "tempo-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tempo-stack.labels" -}}
helm.sh/chart: {{ include "tempo-stack.chart" . }}
{{ include "tempo-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tempo-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tempo-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Tempo labels
*/}}
{{- define "tempo-stack.tempo.labels" -}}
helm.sh/chart: {{ include "tempo-stack.chart" . }}
{{ include "tempo-stack.tempo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: tempo
{{- end }}

{{/*
Tempo selector labels
*/}}
{{- define "tempo-stack.tempo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tempo-stack.name" . }}-tempo
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: tempo
{{- end }}

{{/*
OpenTelemetry Collector labels
*/}}
{{- define "tempo-stack.otelCollector.labels" -}}
helm.sh/chart: {{ include "tempo-stack.chart" . }}
{{ include "tempo-stack.otelCollector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: otel-collector
{{- end }}

{{/*
OpenTelemetry Collector selector labels
*/}}
{{- define "tempo-stack.otelCollector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tempo-stack.name" . }}-otel-collector
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: otel-collector
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tempo-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tempo-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
