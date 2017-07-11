use "net/http"

class val HandlerMaker is HandlerFactory
  let _out: StdStream tag

  new val create(out: StdStream) =>
    _out = out
  
  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    Handler(_out, session)

class Handler is HTTPHandler
  let _out: StdStream tag
  let _session: HTTPSession

  new create(out: StdStream tag, session: HTTPSession tag) =>
    _out = out
    _session = session

  fun ref apply(request: Payload val): Any =>
    let response = request.response()
    let resp = "sup dood\nURL: " + request.url.string() + "\n"
    response.add_chunk(resp)
    _session(consume response)
