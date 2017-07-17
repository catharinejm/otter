use "collections"
use "crypto"
use "itertools"
use "time"

interface tag MessageHandler
  be apply(event: Event)

actor Subscriber
  let _handler: MessageHandler
  let _out: StdStream
  let _subscriptions: MapIs[Publisher, Bytes] = MapIs[Publisher, Bytes]

  fun _rolling_md5(publisher: Publisher): Bytes =>
    try _subscriptions(publisher) else recover Bytes end end

  new create(out': StdStream, handler': MessageHandler) =>
    _handler = handler'
    _out = out'

  be apply(publisher: Publisher, event: Event, md5: Bytes) =>
    let new_md5 = Hasher(_rolling_md5(publisher), event)
    if Arrays.equal[U8](md5, new_md5) then
      _subscriptions(publisher) = new_md5
      _handler(event)
    else
      publisher.block(this)
      _out.print("MD5 does not match!")
      _out.print("Expected: " + Printer.hex(md5))
      _out.print("Actual:   " + Printer.hex(new_md5))
      // re-sync
    end

  be _sub_notify(publisher: Publisher, last_md5: Bytes) =>
    _subscriptions(publisher) = last_md5

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

