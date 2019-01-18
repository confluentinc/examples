package io.confluent.examples.clients.cloud.util

import java.nio.file.Files
import java.nio.file.Paths

class PropertiesLoader {

  static Properties loadConfig(String configFile) {
    if (!Files.exists(Paths.get(configFile))) {
      throw new IOException(configFile + " not found.")
    }
    def cfg = new Properties()

    def propertiesFile = new File(configFile)
    propertiesFile.withInputStream {
      cfg.load(it)
    }
    cfg
  }
}
