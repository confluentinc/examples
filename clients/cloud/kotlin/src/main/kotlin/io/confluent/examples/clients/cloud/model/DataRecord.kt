package io.confluent.examples.clients.cloud.model

import com.google.gson.Gson

val gson = Gson()

data class DataRecord(var count: Long = 0L) {
  override fun toString(): String {
    return gson.toJson(this)
  }
}
