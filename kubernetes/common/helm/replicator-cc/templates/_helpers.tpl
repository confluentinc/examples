{{/*
This function expects kafka dict which can be passed as a global function
The function return protocol name as supported by Kafka
1. SASL_PLAINTEXT
2. SASL_SSL
3. PLAINTEXT
4. SSL
5. 2WAYSSL (*Custom)
*/}}
{{- define "kafka-external-advertise-protocol" }}
{{ $kafka := $.kafkaDependency }}
{{- if not $kafka.tls.enabled }}
    {{- print "SASL_PLAINTEXT" -}}
{{- else if not $kafka.tls.authentication }}
    {{- if $kafka.tls.internal }}
        {{- print "SSL" -}}
    {{- else}}  
        {{- "PLAINTEXT" -}} 
    {{- end }}
{{- else if $kafka.tls.authentication.type }}
    {{- if (eq $kafka.tls.authentication.type "plain") }}
        {{- if $kafka.tls.internal }}
            {{- "SASL_SSL" -}}
        {{- else }}
            {{- print "SASL_PLAINTEXT" -}}
        {{- end }}
    {{- else if eq $kafka.tls.authentication.type "tls" }}
        {{- if $kafka.tls.internal }}
            {{- print "2WAYSSL" -}}
        {{- else }}
            {{- "PLAINTEXT" -}}
        {{- end }}
    {{- else }}
        {{- $_ := fail "Supported authentication type is plain/tls" }}
    {{- end }}
{{- else if empty $kafka.tls.authentication.type }}
    {{- if $kafka.tls.internal }}
        {{- print "SSL" -}}
    {{- else}}  
        {{- "PLAINTEXT" -}} 
    {{- end }}
{{- end }}
{{- end }}

{{- define "kafka-jaas-config" }}
{{ printf "org.apache.kafka.common.security.plain.PlainLoginModule required username=\\\"%s\\\" password=\\\"%s\\\";" $.username $.password }}
{{- end }}
