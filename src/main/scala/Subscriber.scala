package otter

import akka.actor.Actor

class Subscriber extends Actor {
  def subNotify(publisher: Publisher, topMD5: Bytes) = ???

  def handle(publisher: Publisher, ev: Event, md5: Bytes) = ???

  private[otter] def sync(publisher: Publisher, events: EventChain) = ???

  private[otter] def syncFail(publisher: Publisher) = ???
}
