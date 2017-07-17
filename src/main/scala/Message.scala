package otter

sealed abstract class Message

sealed abstract class PublisherMessage extends Message
case class Sub(sub: Subscriber) extends PublisherMessage
case class Unsub(sub: Subscriber) extends PublisherMessage
case class Trigger(ev: Event) extends PublisherMessage
case class Block(sub: Subscriber) extends PublisherMessage
case class Unblock(sub: Subscriber) extends PublisherMessage
