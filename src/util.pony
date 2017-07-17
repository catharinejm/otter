use p = "collections/persistent"
use "crypto"
use "format"
use "itertools"

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
