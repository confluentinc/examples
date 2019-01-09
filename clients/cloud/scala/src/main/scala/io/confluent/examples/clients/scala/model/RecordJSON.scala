package io.confluent.examples.clients.scala.model

class RecordJSON() {
  private[model] var count = 0L

  def this(count: Long) {
    this()
    this.count = count
  }

  def getCount: Long = count
}
