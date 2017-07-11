use "net"

class TCPNotify is TCPConnectionNotify
  let _out: StdStream

  new create(out: StdStream) =>
    _out = out

  fun accepted(conn: TCPConnection ref) =>
    _out.print("tcp conn accepted")

  fun connecting(conn: TCPConnection ref, count: U32) =>
    _out.print("tcp conn connecting (attempt " + count.string() + ")")

  fun connected(conn: TCPConnection ref) =>
    _out.print("tcp conn connected")

  fun connect_failed(conn: TCPConnection ref) =>
    _out.print("tcp conn failed")

  fun auth_failed(conn: TCPConnection ref) =>
    _out.print("tcp auth failed")

  fun sent(conn: TCPConnection ref, data: (String val | Array[U8 val] val)): (String val | Array[U8 val] val) =>
    _out.print("tcp data sent")
    data

  fun sentv(conn: TCPConnection ref, data: ByteSeqIter val): ByteSeqIter val =>
    _out.print("tcp data sentv")
    data

  fun received(conn: TCPConnection ref, data: Array[U8 val] iso, times: USize): Bool =>
    _out.print("tcp data received")
    false

  fun expect(conn: TCPConnection ref, qty: USize): USize =>
    _out.print("tcp data expected (" + qty.string() + " bytes)")
    qty

  fun closed(conn: TCPConnection ref) =>
    _out.print("tcp conn closed")

  fun throttled(conn: TCPConnection ref) =>
    _out.print("tcp conn throttled")

  fun unthrottled(conn: TCPConnection ref) =>
    _out.print("tcp conn unthrottled")
