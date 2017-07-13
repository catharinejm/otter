use "collections"
use "itertools"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
    let chan = Channel[U32]
    Reader(_out, chan)
    chan.write(123)
    chan.read({(n: U32) => _out.print("received: " + n.string())} val)
    chan.read({(n: U32) => _out.print("received: " + n.string())} val)
    chan.write(456)
    
actor Reader

  let _chan: Channel[U32]
  
  new create(out: StdStream, chan': Channel[U32]) =>
    _chan = chan'


actor Channel[A: Any val]

  let _chan: _InnerChannel[A] = _InnerChannel[A]

  be write(a: A) =>
    let self: Channel[A] tag = this
    let handler =
      {(ma: (A | None)) =>
        match ma
          | let a: A => self.write(a)
          else None
        end
      } val
    _chan.write(a, handler)

  be read(cb: {(A)} val) =>
    let self: Channel[A] tag = this
    let handler =
      {(ma: (A | None)) =>
        match ma
          | None => self.read(cb)
          | let a: A => cb(a)
        end
      } val
    _chan.read(handler)

actor _InnerChannel[A: Any val]

  var _buf: (A | None) = None

  be write(a: A, cb: {((A | None))} val) =>
    match _buf
      | None =>
        _buf = a
        cb(None)
      | let olda: A =>
        _buf = olda
        cb(a)
    end

  be read(cb: {((A | None))} val) =>
    cb(_buf = None)
