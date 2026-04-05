{{- define "home-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "home-backend.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "home-backend.name" . -}}
{{- end -}}
{{- end -}}

{{- define "home-backend.ecrRepositoryName" -}}
{{- regexReplaceAll "^[^/]+/" .Values.image.repository "" -}}
{{- end -}}
