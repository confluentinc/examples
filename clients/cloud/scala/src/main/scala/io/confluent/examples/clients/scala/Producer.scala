package io.confluent.examples.clients.scala

import java.util.Properties
import com.typesafe.config.{Config, ConfigFactory}
import org.apache.kafka.clients.producer.{KafkaProducer, ProducerRecord}

object Producer extends App {
  var conf = ConfigFactory.load("ccloud.properties")
  val props = propsFromConfig(conf)
  val producer = new KafkaProducer[String, String](props)
  for( i <- 1 to 10) {
    val record = new ProducerRecord[String, String]("testtopic", "key1", "val"+i)
    producer.send(record)
  }
  producer.close()


  def propsFromConfig(config: Config): Properties = {
    val properties = new Properties()
    properties.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    properties.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    config.entrySet.forEach(e => properties.setProperty(e.getKey, config.getString(e.getKey)))
    properties
  }
}

