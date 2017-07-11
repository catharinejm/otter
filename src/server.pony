use "net/http"

class Notify is ServerNotify
  let _out: StdStream tag

  new create(out: StdStream tag) =>
    _out = out

  fun ref listening(server: HTTPServer ref) =>
    try
      (let addr, let port) = server.local_address().name()
      _out.print("listening to " + addr + ":" + port)
    else
      _out.print("listening, but failed to query local_address")
    end

  fun ref not_listening(server: HTTPServer ref) =>
    _out.print("not listening")

  fun ref closed(server: HTTPServer ref) =>
    _out.print("closed")

