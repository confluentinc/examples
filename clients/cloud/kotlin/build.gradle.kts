import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

group = "io.confluent.confluent"

plugins {
  java
  kotlin("jvm") version "1.8.21"
}
kotlin {
    jvmToolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}



dependencies {
  implementation("org.apache.kafka:kafka-clients:3.5.0")
  implementation("org.apache.kafka:kafka-streams:3.5.0")
  implementation("org.apache.kafka:connect-runtime:3.5.0")
  implementation("io.confluent:kafka-json-serializer:5.0.1")
  implementation("org.slf4j:slf4j-api:2.0.5")
  implementation("org.slf4j:slf4j-log4j12:2.0.5")
  implementation("com.fasterxml.jackson.core:jackson-databind:2.15.1")
  implementation("com.google.code.gson:gson:2.10.1")
}

repositories {
  mavenCentral()
  maven { url = uri("https://packages.confluent.io/maven/")}
  maven { url = uri("https://maven.pkg.jetbrains.space/public/p/ktor/eap") }
}

val configPath: String by project
val topic: String by project
val mainClass: String by project

tasks.withType<KotlinCompile> {
  kotlinOptions.jvmTarget = "17"
}

task("runApp", JavaExec::class) {
  classpath = sourceSets["main"].runtimeClasspath
  mainClass.set("io.confluent.examples.clients.cloud.ProducerExample")
  args = listOf(configPath, topic)
}