.. _ccloud-monitoring-general-request-rate-limit:

Request rate limits
********************

If request limits are hit, clients may be throttled to keep the cluster stable. This throttling
would register as non-zero values for the producer client ``produce-throttle-time-max`` and
``produce-throttle-time-avg`` metrics and consumer client ``fetch-throttle-time-max`` and ``fetch-throttle-time-avg`` metrics.