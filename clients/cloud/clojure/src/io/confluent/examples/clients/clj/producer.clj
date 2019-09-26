(ns io.confluent.examples.clients.clj.producer
  (:require
   [clojure.data.json :as json]
   [clojure.java.io :as jio])
  (:import
   (java.util Properties)
   (org.apache.kafka.clients.admin AdminClient NewTopic)
   (org.apache.kafka.clients.producer Callback KafkaProducer ProducerConfig ProducerRecord)
   (org.apache.kafka.common.errors TopicExistsException)))

(defn- build-properties [config-fname]
  (with-open [config (jio/reader config-fname)]
    (doto (Properties.)
      (.load config)
      (.putAll {ProducerConfig/KEY_SERIALIZER_CLASS_CONFIG "org.apache.kafka.common.serialization.StringSerializer"
                ProducerConfig/VALUE_SERIALIZER_CLASS_CONFIG "org.apache.kafka.common.serialization.StringSerializer"}))))

(defn- create-topic! [topic partitions replication cloud-config]
  (let [ac (AdminClient/create cloud-config)]
    (try
      (.createTopics ac [(NewTopic. topic partitions replication)])
      ;; Ignore TopicExistsException, which would get thrown if the topic was previously created
      (catch TopicExistsException e nil)
      (finally
        (.close ac)))))

(defn producer! [config-fname topic]
  (let [props (build-properties config-fname)]
    (with-open [producer (KafkaProducer. props)]
      (create-topic! topic 1 3 props)
      (let [k "alice"
            ;; We can use callbacks to handle the result of a send, like this:
            callback (reify Callback
                       (onCompletion [this metadata exception]
                         (println (apply str (if exception
                                               ["Failed to produce: " exception]
                                               ["Produced record at " metadata])))))]
        (doseq [i (range 1 6)]
          (.send producer
                 (ProducerRecord. topic k (json/write-str {:count i}))
                 callback))
        (.flush producer)
        ;; Or we could wait for the returned futures to resolve, like this:
        (let [futures (doall
                       (map
                        #(.send producer
                                (ProducerRecord. topic k (json/write-str {:count %})))
                        (range 6 11)))]
          (.flush producer)
          (while (not-every? future-done? futures)
            (Thread/sleep 50))
          (doseq [fut futures]
            (try
              (let [metadata (deref fut)]
                (println (str "Produced record at " metadata)))
              (catch Exception e
                (println (str "Failed to produce: " e)))))))
      (println "Wrote ten records to " topic))))
