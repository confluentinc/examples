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
      "org.apache.kafka" % "kafka-clients" % "2.0.1"
    )

  )


