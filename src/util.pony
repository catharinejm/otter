use "collections"
use p = "collections/persistent"
use "crypto"
use "format"
use "itertools"

type Events is p.Vec[Event]
type Bytes is Array[U8] val

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

primitive ListClone
  fun apply[T: Any #share](l: List[T]): List[T] iso^ =>
    let l': List[T] iso = recover List[T] end
    for v in l.values() do
      l'.push(v)
    end
    consume l'

// Vec#slice is broken- it always returns an empty vec.
primitive Slice
  fun apply[T: Any #share](vec: p.Vec[T], from: USize = 0, to: USize = -1, step: USize = 1): p.Vec[T] =>
    var res = p.Vec[T]
    for i in Range(from, if vec.size() < to then vec.size() else to end, step) do
      try res = res.push(vec(i)) end
    end
    res


primitive Hasher
  fun apply(md5: Bytes, ev: Event): Bytes =>
    let bys = recover val
      let b = md5.clone()
      b.concat(ev.bytes().values())
      b
    end
    MD5(bys)

primitive Printer
  fun hex(bytes: Bytes): String =>
    recover
      let res = String(bytes.size() * 2)
      for b in bytes.values() do
        res.concat(Format.int[U8](b, FormatHexBare where width = 2, fill = '0').values())
      end
      res
    end
