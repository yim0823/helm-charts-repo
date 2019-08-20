{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "haproxy-redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "haproxy-redis.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- /*
Credit: @technosophos
https://github.com/technosophos/common-chart/
labels.standard prints the standard Helm labels.
The standard labels are frequently used in metadata.
*/ -}}
{{- define "labels.standard" -}}
app: {{ template "haproxy-redis.name" . }}
heritage: {{ .Release.Service | quote }}
release: {{ .Release.Name | quote }}
chart: {{ template "chartref" . }}
{{- end -}}

{{- /*
Credit: @technosophos
https://github.com/technosophos/common-chart/
chartref prints a chart name and version.
It does minimal escaping for use in Kubernetes labels.
Example output:
  zookeeper-1.2.3
  wordpress-3.2.1_20170219
*/ -}}
{{- define "chartref" -}}
  {{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "haproxy-redis.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "haproxy-redis.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create HAProxy master backends list
*/}}
{{- define "masters.list" -}}
{{- $name := required "A valid Redis releaseName entry required!" .Values.redis.releaseName -}}
{{- $namespace := required "A valid Redis releaseNamespace entry required!" .Values.redis.releaseNamespace -}}
{{- $serviceName := required "A valid Redis serviceName entry required!" .Values.redis.serviceName -}}
{{- $port := ( required "A valid Redis port entry required!" .Values.redis.port | int ) -}}
{{- $conns := ( required "A valid Redis maxConnections entry required!" .Values.redis.maxConnections | int) -}}
{{- $chksec := ( required "A valid Redis checkSeconds entry required!" .Values.redis.checkSeconds | int) -}}
{{- range $i, $e := until ( required "A valid Redis replicaCount entry required!" .Values.redis.replicaCount | int ) }}
      {{ printf "server master-%d %s-server-%d.%s.%s:%d maxconn %d check inter %ds" $i $name $i $serviceName $namespace $port $conns $chksec}}
{{- end -}}
{{- end -}}

{{/*
Create HAProxy slaves backends list
*/}}
{{- define "slaves.list" -}}
{{- $name := required "A valid Redis releaseName entry required!" .Values.redis.releaseName -}}
{{- $namespace := required "A valid Redis releaseNamespace entry required!" .Values.redis.releaseNamespace -}}
{{- $serviceName := required "A valid Redis serviceName entry required!" .Values.redis.serviceName -}}
{{- $port := ( required "A valid Redis port entry required!" .Values.redis.port | int ) -}}
{{- $conns := ( required "A valid Redis maxConnections entry required!" .Values.redis.maxConnections | int) -}}
{{- $chksec := ( required "A valid Redis checkSeconds entry required!" .Values.redis.checkSeconds | int) -}}
{{- range $i, $e := until ( required "A valid Redis replicaCount entry required!" .Values.redis.replicaCount | int ) }}
      {{ printf "server slave-%d %s-server-%d.%s.%s:%d maxconn %d check inter %ds" $i $name $i $serviceName $namespace $port $conns $chksec}}
{{- end -}}
{{- end -}}
