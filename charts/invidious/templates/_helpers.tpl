{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "invidious.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "invidious.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Render Invidious configuration. Secret values are expanded by Kubernetes
from env variables declared before INVIDIOUS_CONFIG in the container spec. */}}
{{- define "invidious.config" -}}
{{- $config := deepCopy .Values.config -}}
{{- $dbHost := .Values.database.external.host -}}
{{- if .Values.database.internal.enabled -}}
  {{- $dbHost = printf "%s-postgresql" (include "invidious.fullname" .) -}}
{{- end -}}
{{- $_ := set $config "db" (dict "user" "$(DB_USER)" "password" "$(DB_PASSWORD)" "host" $dbHost "port" .Values.database.external.port "dbname" .Values.database.auth.database) -}}
{{- $_ := set $config "hmac_key" "$(HMAC_KEY)" -}}
{{- $_ := set $config "po_token" "$(PO_TOKEN)" -}}
{{- $_ := set $config "visitor_data" "$(VISITOR_DATA)" -}}
{{- $_ := set $config "invidious_companion_key" "$(INVIDIOUS_COMPANION_KEY)" -}}
{{- $companion := .Values.companion | default dict -}}
{{- $companionEnabled := dig "enabled" (.Values.services.companion.enabled | default false) $companion -}}
{{- if and $companionEnabled (empty (get $config "invidious_companion")) -}}
  {{- $_ := set $config "invidious_companion" (list (dict "private_url" (printf "http://%s-companion:8282/companion" (include "invidious.fullname" .)))) -}}
{{- end -}}
{{- toYaml $config -}}
{{- end -}}

{{/* Environment shared by the application and migration init container. */}}
{{- define "invidious.env" -}}
{{- $secretName := required "secret.name must reference an existing Kubernetes Secret" .Values.secret.name -}}
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ .Values.secret.keys.databaseUsername }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ .Values.secret.keys.databasePassword }}
- name: HMAC_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ .Values.secret.keys.hmacKey }}
- name: PO_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ .Values.secret.keys.poToken }}
- name: VISITOR_DATA
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ .Values.secret.keys.visitorData }}
- name: INVIDIOUS_COMPANION_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secretName }}
      key: {{ .Values.secret.keys.companionKey }}
- name: INVIDIOUS_CONFIG
  value: |
    {{- include "invidious.config" . | nindent 4 }}
{{- end -}}
