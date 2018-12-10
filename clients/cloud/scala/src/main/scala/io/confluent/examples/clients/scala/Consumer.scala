package io.confluent.examples.clients.scala

import java.time.Duration
import java.util.{Collections, Properties}

import com.typesafe.config.{Config, ConfigFactory}
import org.apache.kafka.clients.consumer.KafkaConsumer
import scala.collection.JavaConversions._

  object Consumer extends App {
    var conf = ConfigFactory.load("ccloud.properties")
    val props = propsFromConfig(conf)
    val consumer = new KafkaConsumer[String, String](props)
    consumer.subscribe(Collections.singletonList("testtopic"))

    while(true) {
      val records = consumer.poll(Duration.ofSeconds(1))
      for (record <- records) {
        System.out.println("Received message: (" + record.key() + ", " + record.value() + ") at offset " + record.offset())
      }
    }
    consumer.close()
    
    def propsFromConfig(config: Config): Properties = {
      val properties = new Properties()
      properties.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
      properties.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
      config.entrySet.forEach(e => properties.setProperty(e.getKey, config.getString(e.getKey)))
      properties
    }

}
