use "time"

primitive _MicroConv
  fun apply(pr: (I64, I64)): I64 =>
    (let secs, let nsecs) = pr
    (secs * 1_000_000) + (nsecs / 1_000)

class val MicroTime
  let _us: I64

  new val create(pr: (I64, I64)) =>
    _us = _MicroConv(pr)

  new val now() =>
    _us = _MicroConv(Time.now())

  fun eq(other: MicroTime): Bool =>
    _us == other._us

  fun lt(other: MicroTime): Bool =>
    _us < other._us

  fun le(other: MicroTime): Bool =>
    _us <= other._us

  fun gt(other: MicroTime): Bool =>
    _us > other._us

  fun ge(other: MicroTime): Bool =>
    _us >= other._us

  fun i64(): I64 =>
    _us

  fun u64(): U64 =>
    _us.u64()

  fun string(): String =>
    _us.string()

