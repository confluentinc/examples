import Dependencies._

lazy val root = (project in file(".")).
  settings(
    inThisBuild(List(
      organization := "com.example",
      scalaVersion := "2.12.5",
      version      := "0.1.0-SNAPSHOT"
    )),
    name := "scalaccloud",
    libraryDependencies ++= Seq(
      "com.typesafe" % "config" % "1.3.2",
      "org.apache.kafka" % "kafka-clients" % "2.1.0",
      "org.apache.kafka" % "connect-json" % "2.1.0",
      "org.apache.kafka" % "connect-runtime" % "2.1.0",
      "org.apache.kafka" % "kafka-streams" % "2.1.0",
      "com.fasterxml.jackson.core" % "jackson-databind" % "2.8.5",
      "javax.ws.rs" % "javax.ws.rs-api" % "2.1.1" artifacts( Artifact("javax.ws.rs-api", "jar", "jar")) // this is a workaround for https://github.com/jax-rs/api/issues/571
    )

  )


