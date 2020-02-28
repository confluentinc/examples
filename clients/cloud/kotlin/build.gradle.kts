import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

group = "io.confluent.confluent"

plugins {
  java
  kotlin("jvm") version "1.3.11"
}

java {
  sourceCompatibility = JavaVersion.VERSION_1_8
  targetCompatibility = JavaVersion.VERSION_1_8
}

dependencies {
  compile(kotlin("stdlib"))
  compile(kotlin("reflect"))

  compile("org.apache.kafka:kafka-clients:2.1.0")
  compile("org.apache.kafka:kafka-streams:2.1.0")
  compile("org.apache.kafka:connect-runtime:2.1.0")
  compile("io.confluent:kafka-json-serializer:5.0.1")
  compile("org.slf4j:slf4j-api:1.7.6")
  compile("org.slf4j:slf4j-log4j12:1.7.6")
  compile("com.fasterxml.jackson.core:jackson-databind:[2.8.11.1,)")
  //compile ("com.fasterxml.jackson.module:jackson-module-kotlin:[2.8.11.1,)")
  compile("com.google.code.gson:gson:2.2.4")
}

repositories {
  jcenter()
  maven(url = "http://packages.confluent.io/maven/")
}

val configPath: String by project
val topic: String by project
val mainClass: String by project

tasks.withType<KotlinCompile> {
  kotlinOptions.jvmTarget = "1.8"
}

task("runApp", JavaExec::class) {
  classpath = sourceSets["main"].runtimeClasspath
  main = mainClass
  args = listOf(configPath, topic)
}