use "collections"
use p = "collections/persistent"
use "crypto"
use "format"
use "itertools"
use "random"
use "time"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
    let pub = Publisher
    // let pub2 = Publisher
    let sub = Subscriber(_out, Announcer(_out))
    pub.sub(sub)
    // pub2.sub(sub)

    let timers = Timers
    timers(Timer(Notify(_out, pub, "Pub 1"), 0, Nanos.from_millis(500)))
    // timers(Timer(Notify(_out, pub, "Pub 2"), Nanos.from_millis(500), Nanos.from_millis(500)))

class iso Notify is TimerNotify
  let _pub: Publisher
  var _count: U32 = 0
  let _out: StdStream
  let _name: String

  new iso create(out': StdStream, pub': Publisher, name': String) =>
    _pub = pub'
    _out = out'
    _name = name'

  fun ref apply(timer: Timer, count: U64): Bool =>
    // _out.print("Timer fired")
    _pub.trigger(Event("Event " + _count.string() + " \"" + _name + "\""))
    _count = _count + 1
    _count < 10
