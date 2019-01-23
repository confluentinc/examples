package io.confluent.examples.clients.cloud.model

import com.google.gson.Gson

data class DataRecord(var count: Long) {
  constructor() : this(0L)

  override fun toString(): String {
    return Gson().toJson(this)
  }
}
