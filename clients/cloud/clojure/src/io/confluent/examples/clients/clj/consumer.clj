(ns io.confluent.examples.clients.clj.consumer
  (:gen-class)
  (:require
   [clojure.data.json :as json]
   [clojure.java.io :as jio])
  (:import
   (java.time Duration)
   (java.util Properties)
   (org.apache.kafka.clients.consumer ConsumerConfig KafkaConsumer)))

(defn- build-properties [config-fname]
  (with-open [config (jio/reader config-fname)]
    (doto (Properties.)
      (.putAll {ConsumerConfig/KEY_DESERIALIZER_CLASS_CONFIG "org.apache.kafka.common.serialization.StringDeserializer"
                ConsumerConfig/VALUE_DESERIALIZER_CLASS_CONFIG "org.apache.kafka.common.serialization.StringDeserializer"})
      (.load config))))

(defn consumer! [config-fname topic]
  (with-open [consumer (KafkaConsumer. (build-properties config-fname))]
    (.subscribe consumer [topic])
    (loop [tc 0
           records []]
      (let [new-tc (reduce
                    (fn [tc record]
                      (let [cnt (get (json/read-str (.value record)) "count")
                            new-tc (+ tc cnt)]
                        (printf "Consumed record with key %s and value %s, total count is %d\n" (.key record) (.value record) new-tc)
                        new-tc))
                        tc
                        records)]
        (println "Polling")
        (recur new-tc (seq (.poll consumer (Duration/ofSeconds 1))))))))

(defn -main [& args]
  (apply consumer! args))
