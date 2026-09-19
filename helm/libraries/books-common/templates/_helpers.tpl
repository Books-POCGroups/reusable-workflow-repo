{{- define "books-common.tlsSecretName" -}}
{{- .Values.ingress.tls.secretName | default (printf "%s-ingress-tls" .Release.Name) -}}
{{- end -}}
