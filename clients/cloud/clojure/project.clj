(defproject io.confluent.examples.clients.clj "0.1.0-SNAPSHOT"
  :license {:name "Apache License, Version 2.0"
            :url "http://www.apache.org/licenses/LICENSE-2.0"}
  :dependencies [[org.clojure/clojure "1.10.0"]
                 [org.clojure/data.json "0.2.6"]
                 [org.apache.kafka/kafka-clients "2.1.0"]]
  :aliases {"consumer" ["run" "-m" "io.confluent.examples.clients.clj.consumer"]
            "producer" ["run" "-m" "io.confluent.examples.clients.clj.producer"]})
