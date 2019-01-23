package io.confluent.examples.clients.cloud.util

import java.io.FileInputStream
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*

fun loadConfig(configFile: String): Properties {
  if (!Files.exists(Paths.get(configFile))) {
    throw IOException("$configFile not found.")
  }
  val cfg = Properties()
  FileInputStream(configFile).use { cfg.load(it) }
  return cfg
}
