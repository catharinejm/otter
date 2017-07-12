use "collections"
use "itertools"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
    Jobs.source[U32](42)
    .run_into(MappedJob[U32, U32]({(x: U32): U32 => x * 2} val)
               .>run_into(
                 object
                   be pour(i: U32) =>
                     env.out.print("received " + i.string())
                 end
               ).>pour(42))

interface tag Sink[A: Any #send]
  be pour(a: A)

interface tag Job[A: Any #send]
  be run_into(sink: Sink[A])

actor MappedJob[A: Any #send, B: Any val] is (Sink[A] & Job[B])
  let _body: {(A): B^} val
  var _result: (B | None) = None
  let _sinks: List[Sink[B]] = List[Sink[B]]

  new create(body: {(A): B^} val) =>
    _body = body

  be pour(a: A) =>
    _result = _body(consume a)
    for sink in _sinks.values() do
      try sink.pour(_result as B) end
    end
    _sinks.clear()

  be run_into(sink: Sink[B]) =>
    match _result
      | let r': B => sink.pour(r')
      | None => _sinks.push(sink)
    end

primitive Jobs
  fun source[A: Any val](a: A): Job[A] =>
    MappedJob[None, A]({(x: None): A^ => a} val).>pour(None)
