use "collections"
use "net"
use "net/http"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
    // match env.root
    //   | None => env.err.print("no ambient auth!")
    //   | let auth: AmbientAuth =>
    //       HTTPServer(
    //         where auth = auth,
    //               logger = CommonLog(env.out),
    //               notify = recover Notify(env.out) end,
    //               handler = HandlerMaker(env.out),
    //               host = "0.0.0.0",
    //               service = "8080"
    //       )
    // end
    let coord = PMapCoordinator[U32, U32](recover Range[U32](1, 20) end, 5, this)
    coord({(x: U32): U32 => x * 2} val)

  be send_result(vs: Iterator[Any val] iso) =>
    _out.write("result: ")
    let vs': Iterator[Any val] ref = consume vs
    for v in vs' do
      match v
        | let n: U32 => _out.write(n.string() + ", ")
        else _out.write("<unknown type>, ")
      end
    end
    _out.print("")

interface tag PMapResult
  be send_result(v: Iterator[Any iso] iso)

actor PMapCoordinator[In: Any val, Out: Any #send]
  let _chunks: List[List[In] val] = List[List[In] val]
  let _endpoint: PMapResult tag

  let _results: MapIs[U32, List[Out]] iso = recover MapIs[U32, List[Out]] end

  new create(vals': Iterator[In] iso, parallelism': U32, endpoint': PMapResult tag) =>
    var i: U32 = 0
    var chunk: List[In] iso = recover List[In] end
    let vs': Iterator[In] ref = consume vals'
    for v in vs' do
      if (i > 0) and ((i % parallelism') == 0) then
        _chunks.push(consume chunk)
        chunk = recover List[In] end
      end
      chunk.push(v)
      i = i + 1
    end
    _endpoint = endpoint'

  be apply(f: {(In): Out} val) =>
    var i: U32 = 0
    for c in _chunks.values() do
      PMapWorker[In, Out](c, i, f, this)
      i = i + 1
    end

  be _receive(chunk: List[Out] iso, cidx: U32) =>
    _results(cidx) = consume chunk
    if _results.size() == _chunks.size() then
      let flat: List[Out] iso = recover List[Out] end
      for ci in Range[U32](0, _chunks.size().u32()) do
        try
          (_, let r: Out) = _results.remove(ci)
          flat.append_list(consume r)
        end
      end
      _endpoint.send_result(flat.values())
    end

actor PMapWorker[In: Any val, Out: Any #send]
  be apply(chunk: List[In] val, cidx: U32, f: {(In): Out} val, coord: PMapCoordinator[In, Out] tag) =>
    let res: List[Out] iso = recover List[Out] end
    for v in chunk.values() do
      let r = f(v)
      res.push(consume r)
    end
