{{/*
Expand the name of the chart.
*/}}
{{- define "grafana-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "grafana-stack.fullname" -}}
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
{{- define "grafana-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "grafana-stack.labels" -}}
helm.sh/chart: {{ include "grafana-stack.chart" . }}
{{ include "grafana-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "grafana-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "grafana-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "grafana-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Alertmanager selector labels
*/}}
{{- define "grafana-stack.alertmanager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana-stack.name" . }}-alertmanager
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Alertmanager labels
*/}}
{{- define "grafana-stack.alertmanager.labels" -}}
helm.sh/chart: {{ include "grafana-stack.chart" . }}
{{ include "grafana-stack.alertmanager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: alertmanager
{{- end }}

{{/*
Grafana selector labels
*/}}
{{- define "grafana-stack.grafana.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana-stack.name" . }}-grafana
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Grafana labels
*/}}
{{- define "grafana-stack.grafana.labels" -}}
helm.sh/chart: {{ include "grafana-stack.chart" . }}
{{ include "grafana-stack.grafana.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: grafana
{{- end }}
