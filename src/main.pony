use "collections"
use p = "collections/persistent"
use "crypto"
use "itertools"
use "random"
use "time"

class val Millis
  let _millis: U64

  new val create(pr: (I64, I64)) =>
    (let secs, let nsecs) = pr
    _millis = (secs.u64() * 1000) + (nsecs.u64() / 1_000_000)

  fun eq(other: Millis): Bool =>
    _millis == other._millis

  fun lt(other: Millis): Bool =>
    _millis < other._millis

  fun le(other: Millis): Bool =>
    _millis <= other._millis

  fun gt(other: Millis): Bool =>
    _millis > other._millis

  fun ge(other: Millis): Bool =>
    _millis >= other._millis

  fun u64(): U64 =>
    _millis

  fun string(): String =>
    _millis.string()

class val Event
  let _ts: Millis val
  let _body: String val

  new val create(body': String val) =>
    _ts = Millis(Time.now())
    _body = body'

  fun ts(): this->Millis! =>
    _ts

  fun body(): this->String! =>
    _body

  fun bytes(): Array[U8] val^ =>
    recover
      let ary = Array[U8]
      ary.concat(_ts.string().array().values())
      ary.concat(_body.array().values())
      ary
     end

type Events is p.Vec[Event]

class val ID
  let _id: U64

  new val create() =>
    (let sec, let nsec) = Time.now()
    _id = Rand(sec.u64(), nsec.u64()).u64()

  fun val eq(other: ID val): Bool =>
    _id == other._id

  fun val u64(): U64 =>
    _id

trait tag MessageActor
  be ack(id: ID)

class iso Session
  let _sender: MessageActor
  let _id: ID

  new iso create(sender': MessageActor) =>
    _sender = sender'
    _id = ID

  fun iso ack() =>
    _sender.ack(_id)

trait tag Pub
  fun ref _subs(): SetIs[Sub]
  fun ref _events(): List[(Bytes, Event)]

  be sub(sub': Sub) =>
    _subs().set(sub')

  be unsub(sub': Sub) =>
    _subs().unset(sub')

  be ask(sub': Sub, ts: Millis) =>
    let events = Iter[(Bytes, Event)](_events().values()).take_while({(pair: (Bytes, Event)): Bool =>
      (let _, let ev) = pair
      ev.ts() >= ts
    } val)
    
    sub'(Events.concat(events.map[Event]({(pair: (Bytes, Event)): Event => pair._2})), try _events()(0)._1 else recover Bytes end end)

  be trigger(ev: Event)

trait tag Sub
  be apply(evs: Events, md5_bys: Bytes)

type Bytes is Array[U8] val

actor UserService is Pub
  let _m_subs: SetIs[Sub] = SetIs[Sub]
  let _m_events: List[(Bytes, Event)] = List[(Bytes, Event)]

  fun ref _subs(): SetIs[Sub] =>
    _m_subs

  fun ref _events(): List[(Bytes, Event)] =>
    _m_events

  be trigger(ev: Event) =>
    let bys: Bytes = try
      (let bys', _) = _events()(0)
      bys'
    else
      recover Bytes end
    end
    let new_bys: Bytes = recover
      let b = Bytes
      b.concat(bys.values())
      b.concat(ev.bytes().values())
      b
    end
    let new_md5 = MD5(new_bys)
    _events().unshift((new_md5, ev))
    for sub in _subs().values() do
      sub(Events.push(ev), new_md5)
    end

primitive Arrays
  fun equal[T: Equatable[T] #read](left: Array[T] box, right: Array[T] box): Bool =>
    if left.size() != right.size() then
      return false
    end
    for (l, r) in Iter[box->T](left.values()).zip[box->T](right.values()) do
      if l != r then
        return false
      end
    end
    true

actor Announcer is Sub

  let _out: StdStream
  var _rolling_md5: Bytes = recover Bytes end

  new create(out': StdStream) =>
    _out = out'

  be apply(events: Events, md5_bys: Bytes) =>
    var new_md5: Bytes = recover Bytes end
    for ev in Iter[Event](events.reverse().values()) do
      let new_bys: Bytes = recover
        let b = new_md5.clone()
        b.concat(ev.bytes().values())
        b
      end
      new_md5 = MD5(new_bys)
    end
    if not Arrays.equal[U8](md5_bys, new_md5) then
      _out.print("**** ERROR: md5 does not match!")
    end
    let now = Millis(Time.now())
    for ev in events.values() do
      let delta_t = now.u64() - ev.ts().u64()
      _out.print("-----------------")
      _out.print("Received event: " + ev.body() + " (ts: " + ev.ts().u64().string() + ")")
      _out.print("  " + delta_t.string() + "ms in transit")
      _out.write("-----------------\n\n")
    end

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out

    let pub = UserService
    let announcer = Announcer(_out)
    pub.sub(announcer)
    let timers = Timers
    let timer = Timer(Notify(pub), 1_000_000_000, 1_000_000_000)
    timers(consume timer)

class iso Notify is TimerNotify
  let _pub: Pub
  var _calls: U64 = 0
  new iso create(pub': Pub) =>
    _pub = pub'

  fun ref apply(timer: Timer, count: U64): Bool =>
    _calls = _calls + 1
    _pub.trigger(Event("Event " + _calls.string()))
    _calls < 10

