use "collections"
use "crypto"
use "itertools"
use "random"
use "time"

interface tag MessageHandler
  be apply(event: Event)

actor Subscriber
  let _handler: MessageHandler
  let _out: StdStream
  let _subscriptions: MapIs[Publisher, Bytes] = MapIs[Publisher, Bytes]
  let _random: Random

  fun _rolling_md5(publisher: Publisher): Bytes =>
    try _subscriptions(publisher) else recover Bytes end end

  new create(out': StdStream, handler': MessageHandler) =>
    _handler = handler'
    _out = out'
    (let sec, let nsec) = Time.now()
    _random = Rand(sec.u64(), nsec.u64())
    for _ in Range[I64](0, (nsec % 100) + 100) do
      _random.next()
    end

  be apply(publisher: Publisher, event: Event, md5: Bytes) =>
    // simulate dropped message
    if (_random.u8() and 0x7) == 0 then
      return
    end

    let new_md5 = Hasher(_rolling_md5(publisher), event)
    if Arrays.equal[U8](md5, new_md5) then
      _subscriptions(publisher) = new_md5
      _handler(event)
    else
      _bad_md5(md5, new_md5)
      publisher.block(this)
      publisher.bulk_fetch(this, _rolling_md5(publisher))
    end

  fun _bad_md5(expected: Bytes, actual: Bytes) =>
    _out.print("MD5 does not match!")
    _out.print("Expected: " + Printer.hex(expected))
    _out.print("Actual:   " + Printer.hex(actual))

  be _sync(publisher: Publisher, events: EventChain val) =>
    _out.print("attempting sync")
    _out.print("rolling MD5: " + Printer.hex(_rolling_md5(publisher)))
    // _out.print("all events:")
    // publisher.print_all_events(_out)
    _out.print("sent events:")
    events.print(_out)
    let new_md5 = recover val
      var prev_md5 = _rolling_md5(publisher)
      for (ev, md5) in events.values() do
        let md5' = Hasher(prev_md5, ev)
        if not Arrays.equal[U8](md5, md5') then
          // handle error
          _bad_md5(md5, md5')
          return
        end
        _handler(ev)
        prev_md5 = md5
      end
      prev_md5
    end
    _subscriptions(publisher) = new_md5
    publisher.unblock(this)

  be _sync_fail(publisher: Publisher) =>
    _out.print("Resync failed!")

  be _sub_notify(publisher: Publisher, last_md5: Bytes) =>
    _subscriptions(publisher) = last_md5
    _out.print("Number of subscriptions: " + _subscriptions.size().string())

actor Announcer is MessageHandler
  let _out: StdStream

  new create(out': StdStream) =>
    _out = out'

  be apply(event: Event) =>
    let now = MicroTime.now()
    let delta_t = now.u64() - event.ts().u64()
    _out.print("-----------------")
    _out.print("Received event: " + event.body() + " (ts: " + event.ts().u64().string() + ")")
    _out.print("  " + delta_t.string() + "us in transit")
    _out.write("-----------------\n\n")

