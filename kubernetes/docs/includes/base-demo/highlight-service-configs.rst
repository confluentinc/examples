::

  kafka:
    <<: *cpImage
    resources:
      cpu: 200m
      memory: 1Gi
    loadBalancer:
      enabled: false
    tls:
      enabled: false
    metricReporter:
      enabled: true
    configOverrides:
      server:
      - "auto.create.topics.enabled=true"

