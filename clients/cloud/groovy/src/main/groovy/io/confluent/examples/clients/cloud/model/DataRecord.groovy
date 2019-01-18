package io.confluent.examples.clients.cloud.model

import groovy.json.JsonOutput
import groovy.transform.Immutable

@Immutable
class DataRecord {

  Long count

  String toString() {
    JsonOutput.toJson(this)
  }
}
