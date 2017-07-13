use "collections"
use "itertools"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out

    let source: Producer[I32] =
      object is Producer[I32]
        let _vals: Iterator[I32] = Range[I32](0, 100)
        let _is_throttled: Bool = false
        be produce_val(cons: Consumer[I32]) =>
          _is_throttled = false
          try cons.consume_val(_vals.next()) end
        be throttle() =>
          _is_throttled = true
      end

trait tag Consumer[A: Any #send]
  be consume_val(a: A)

trait tag Producer[A: Any #send]
  be produce_val(cons: Consumer[A])
  be throttle(a: A)

interface val FlowFn[A: Any #send, B: Any #send]
  fun val apply(a: A): B

actor Flow[A: Any #send, B: Any #send] is (Consumer[A] & Producer[B])
  let _f: FlowFn[A, B]
  let _source: Producer[A]
  var _can_accept_more: Bool = true
  var _dest: Consumer[B]

  var _retry_queue: List[B]
  
  new create(source': Producer[A], dest': Consumer[B], f': FlowFn[A, B]) =>
    _f = f'
    _source = source'
    _dest = dest'

  be consume_val(a: A) =>
    if _can_accept_more then
      _dest.consume_val(_f(a))
    else
      _source.throttle(a)
    end

  be throttle(b: B) =>
    _can_accept_more = false
    _retry_queue.push(b)
  
  be produce_val(cons: Consumer[B]) =>
    _can_accept_more = true
    try
      _dest.consume_val(_retry_queue.shift())
    else
      _source.produce_val(this)
    end

// trait Flow[A: Any #send, B: Any #send]
//   fun then[C: Any #send](flow: Flow[B, C]): Flow[A, C]

// trait tag Sink[A: Any #send]
//   be apply(a: A)

// trait Source[A: Any #send]
//   fun via[B: Any #send](flow: Flow[A, B]): Source[B]
//   fun to(sink: Sink[A]): Stream

// trait Stream
//   fun run()
