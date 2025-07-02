{{/*
Expand the name of the chart.
*/}}
{{- define "loki-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "loki-stack.fullname" -}}
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
{{- define "loki-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "loki-stack.labels" -}}
helm.sh/chart: {{ include "loki-stack.chart" . }}
{{ include "loki-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "loki-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "loki-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Loki labels
*/}}
{{- define "loki-stack.loki.labels" -}}
helm.sh/chart: {{ include "loki-stack.chart" . }}
{{ include "loki-stack.loki.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: loki
{{- end }}

{{/*
Loki selector labels
*/}}
{{- define "loki-stack.loki.selectorLabels" -}}
app.kubernetes.io/name: loki
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Fluent Bit labels
*/}}
{{- define "loki-stack.fluentbit.labels" -}}
helm.sh/chart: {{ include "loki-stack.chart" . }}
{{ include "loki-stack.fluentbit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: fluent-bit
{{- end }}

{{/*
Fluent Bit selector labels
*/}}
{{- define "loki-stack.fluentbit.selectorLabels" -}}
app.kubernetes.io/name: fluent-bit
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use for Fluent Bit
*/}}
{{- define "loki-stack.fluentbit.serviceAccountName" -}}
{{- if .Values.fluentbit.serviceAccount.create }}
{{- default (printf "%s-fluent-bit" (include "loki-stack.fullname" .)) .Values.fluentbit.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.fluentbit.serviceAccount.name }}
{{- end }}
{{- end }}
