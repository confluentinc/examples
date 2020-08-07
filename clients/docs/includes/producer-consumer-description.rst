In this example, the producer application writes |ak| data to a topic in your |ak| cluster.
If the topic does not already exist in your |ak| cluster, the producer application will use the Kafka Admin Client API to create the topic.
Each record written to |ak| has a key representing a username (for example, ``alice``) and a value of a count, formatted as json (for example, ``{"count": 0}``).
The consumer application reads the same |ak| topic and keeps a rolling sum of the count as it processes each record.
