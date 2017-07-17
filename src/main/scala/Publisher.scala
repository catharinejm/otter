package otter

import akka.actor.Actor

class EventChain private (private var _vec: Vector[(Event, Bytes)]) {

  def this() = this(Vector.empty)

  def topMD5: Bytes =
    _vec.lastOption map (_._2) getOrElse Bytes()

  def add(ev: Event): Bytes = {
    val md5 = (topMD5 ++ ev.bytes).md5
    _vec = _vec :+ (ev -> md5)
    md5
  }

  def from(md5: Bytes): Option[EventChain] = {
    if (md5.isEmpty) {
      Some(new EventChain(_vec))
    } else {
      Some(_vec.dropWhile(_._2 != md5).drop(1)) filter (_.nonEmpty) map (new EventChain(_))
    }
  }
    
}

class Publisher extends Actor {
  private var _subs: Map[Subscriber, Boolean] = Map.empty
  private val _events: EventChain = new EventChain

  def sub(sub: Subscriber): Unit = {
    _subs = _subs + (sub -> false)
    sub.subNotify(this, _events.topMD5)
  }

  def unsub(sub: Subscriber): Unit =
    _subs = _subs - sub

  def trigger(ev: Event): Unit = {
    val md5 = _events.add(ev)
    for {
      (sub, blocked) <- _subs
      if !blocked
    } sub.handle(this, ev, md5)
  }

  def block(sub: Subscriber): Unit =
    _subs = _subs + (sub -> true)

  def unblock(sub: Subscriber): Unit =
    if (_subs.contains(sub))
      _subs = _subs + (sub -> false)

  def bulkFetch(sub: Subscriber, md5: Bytes) =
    _events.from(md5) map (sub.sync(this, _)) getOrElse sub.syncFail(this)

  final val handleMessage: PublisherMessage =/>: Unit = {
    case Sub(s) => sub(s)
    case Unsub(s) => unsub(s)
    case Trigger(ev) => trigger(ev)
    case Block(s) => block(s)
    case Unblock(s) => unblock(s)
  }

  final val receive: Any =/>: Unit = {
    case pm: PublisherMessage => handleMessage(pm)
    case unknown => println(s"received unknown message: $unknown")
  }
}
