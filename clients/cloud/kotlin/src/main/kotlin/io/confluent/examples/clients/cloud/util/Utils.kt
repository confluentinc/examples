package io.confluent.examples.clients.cloud.util

import java.io.FileInputStream
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*

fun loadConfig(configFile: String) = FileInputStream(configFile).use {
  Properties().apply {
    load(it)
  }
}