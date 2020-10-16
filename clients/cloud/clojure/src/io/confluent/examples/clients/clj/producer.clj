(ns io.confluent.examples.clients.clj.producer
  (:gen-class)
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
      (.putAll {ProducerConfig/KEY_SERIALIZER_CLASS_CONFIG "org.apache.kafka.common.serialization.StringSerializer"
                ProducerConfig/VALUE_SERIALIZER_CLASS_CONFIG "org.apache.kafka.common.serialization.StringSerializer"})
      (.load config))))

(defn- create-topic! [topic partitions replication cloud-config]
  (let [ac (AdminClient/create cloud-config)]
    (try
      (.createTopics ac [(NewTopic. topic partitions replication)])
      ;; Ignore TopicExistsException, which would get thrown if the topic was previously created
      (catch TopicExistsException e nil)
      (finally
        (.close ac)))))

(defn producer! [config-fname topic]
  (let [props (build-properties config-fname)
        print-ex (comp println (partial str "Failed to deliver message: "))
        print-metadata #(printf "Produced record to topic %s partition [%d] @ offest %d\n"
                                (.topic %)
                                (.partition %)
                                (.offset %))
        create-msg #(let [k "alice"
                          v (json/write-str {:count %})]
                      (printf "Producing record: %s\t%s\n" k v)
                      (ProducerRecord. topic k v))]
    (with-open [producer (KafkaProducer. props)]
      (create-topic! topic 1 3 props)
      (let [;; We can use callbacks to handle the result of a send, like this:
            callback (reify Callback
                       (onCompletion [this metadata exception]
                         (if exception
                           (print-ex exception)
                           (print-metadata metadata))))]
        (doseq [i (range 5)]
          (.send producer (create-msg i) callback))
        (.flush producer)
        ;; Or we could wait for the returned futures to resolve, like this:
        (let [futures (doall (map #(.send producer (create-msg %)) (range 5 10)))]
          (.flush producer)
          (while (not-every? future-done? futures)
            (Thread/sleep 50))
          (doseq [fut futures]
            (try
              (let [metadata (deref fut)]
                (print-metadata metadata))
              (catch Exception e
                (print-ex e))))))
      (printf "10 messages were produced to topic %s!\n" topic))))

(defn -main [& args]
  (apply producer! args))
