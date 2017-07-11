// use "collections"
use "net"
use "net/http"
// use "random"
// use "time"

actor Main
  new create(env: Env) =>
    match env.root
      | None => env.err.print("no ambient auth!")
      | let auth: AmbientAuth =>
          let server = HTTPServer(
            where auth = auth,
                  logger = CommonLog(env.out),
                  notify = recover Notify(env.out) end,
                  handler = HandlerMaker(env.out),
                  host = "0.0.0.0",
                  service = "8080"
          )
          // let tcp = TCPConnection(
          //   where auth = auth,
          //         notify = recover TCPNotify(env.out) end,
          //         host = "0.0.0.0",
          //         service = "8080"
          // )
          // server.register_session(tcp)
    end
