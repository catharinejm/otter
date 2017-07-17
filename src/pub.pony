use "collections"
use "crypto"
use "itertools"
use "time"

class EventChain
  let _events: List[Event] = List[Event]
  let _md5s: List[Bytes] = List[Bytes]

  fun top_md5(): Bytes =>
    try _md5s(0) else recover Bytes end end

  fun _hash(ev: Event): Bytes =>
    Hasher(top_md5(), ev)

  fun ref add(ev: Event): Bytes =>
    _events.unshift(ev)
    let md5 = _hash(ev)
    _md5s.unshift(md5)
    md5

class SubscriberSet
  let _subs: MapIs[Subscriber, Bool] = MapIs[Subscriber, Bool]

  fun values(): Iterator[(Subscriber, Bool)]^ =>
    _subs.pairs()

  fun ref add(sub: Subscriber) =>
    _subs(sub) = false

  fun ref block(sub: Subscriber): None ? =>
    if _subs.contains(sub) then
      _subs(sub) = true
    else
      error
    end

  fun ref unblock(sub: Subscriber): None ? =>
    if _subs.contains(sub) then
      _subs(sub) = false
    else
      error
    end

actor Publisher
  let _subs: SubscriberSet = SubscriberSet
  let _events: EventChain = EventChain

  be sub(sub': Subscriber) =>
    _subs.add(sub')
    sub'._sub_notify(this, _events.top_md5())

  be trigger(ev: Event) =>
    let md5 = _events.add(ev)
    for (sub', blocked) in _subs.values() do
      if not blocked then
        sub'(this, ev, md5)
      end
    end

  be block(sub': Subscriber) =>
    try _subs.block(sub') end

  be unblock(sub': Subscriber) =>
    try _subs.unblock(sub') end
