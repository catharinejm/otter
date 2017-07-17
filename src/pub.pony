use "collections"
use p = "collections/persistent"
use "crypto"
use "itertools"
use "time"

class EventChain
  var _events: p.Vec[Event] = p.Vec[Event]
  var _md5s: p.Vec[Bytes] = p.Vec[Bytes]

  new create() =>
    None

  new val _dup(events': p.Vec[Event], md5s': p.Vec[Bytes]) =>
    _events = events'
    _md5s = md5s'

  fun top_md5(): Bytes =>
    try _md5s(_md5s.size() - 1) else recover Bytes end end

  fun _hash(ev: Event): Bytes =>
    Hasher(top_md5(), ev)

  fun ref add(ev: Event): Bytes =>
    _events = _events.push(ev)
    let md5 = _hash(ev)
    _md5s = _md5s.push(md5)
    md5

  fun ref from(md5: Bytes): EventChain val ? =>
    if md5.size() == 0 then
      return EventChain._dup(_events, _md5s)
    end
    var drop_amt: (USize | None) = None
    for (i, m) in _md5s.pairs() do
      if Arrays.equal[U8](m, md5) then
        drop_amt = i + 1
        break
      end
    end
    EventChain._dup(
      Slice[Event](_events, drop_amt as USize),
      Slice[Bytes](_md5s, drop_amt as USize)
    )

  fun print(out: StdStream) =>
    for (ev, md5) in values() do
      out.print(ev.body())
      out.print(Printer.hex(md5))
      out.write("\n")
    end

  fun values(): Iterator[(Event, Bytes)]^ =>
    Iter[Event](_events.values()).zip[Bytes](_md5s.values())

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

  be bulk_fetch(sub': Subscriber, md5: Bytes) =>
    try
      sub'._sync(this, _events.from(md5))
    else
      sub'._sync_fail(this)
    end

  be print_all_events(out: StdStream) =>
    _events.print(out)
