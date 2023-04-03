(defproject io.confluent.examples.clients.clj "0.1.0-SNAPSHOT"
  :license {:name "Apache License, Version 2.0"
            :url "http://www.apache.org/licenses/LICENSE-2.0"}
  :dependencies [[org.clojure/clojure "1.10.3"]
                 [org.clojure/data.json "2.4.0"]
                 [org.apache.kafka/kafka-clients "2.8.0"]]
  :aliases {"consumer" ["run" "-m" "io.confluent.examples.clients.clj.consumer"]
            "producer" ["run" "-m" "io.confluent.examples.clients.clj.producer"]})
