use "collections"
use "itertools"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
    run()
    
  fun tag run() =>
    let l: List[U32] val = recover
      let l' = List[U32]
      l'.concat(Range[U32](0, 100))
      l'
    end
    PMapper[U32, U32](
      l,
      {(x: U32): U32^ => x * 2} val,
      {(xs: List[U32] val, ixs: List[USize] val)(self = this) =>
        self._print_list[U32](xs)
        self._print[String]("is sorted? " + self.is_sorted(ixs).string())
        if not self.is_sorted(ixs) then
          self._print_list[USize](ixs)
        end
      } val
    )

  fun tag is_sorted(list: List[USize] val): Bool =>
    for (f, s) in Iter[USize](list.values()).zip[USize](Iter[USize](list.values()).skip(1)) do
      if f > s then return false end
    end
    true

  be _print[X: Stringable val](x: X) =>
    _out.print(x.string())

  be _print_list[X: Stringable #read](lis: List[X] val) =>
    _out.write("[")
    for x in lis.values() do
      _out.write(x.string() + ", ")
    end
    if lis.size() > 0 then
      _out.write("\b\b")
    end
    _out.print("]")

actor PMapper[A: Any val, B: Any val]
  be apply(input: List[A] val, f: {(A): B^} val, cb: {(List[B] val, List[USize] val)} val) =>
    let hop = _Hopper[B](cb, input.size())
    for (v, i) in Zip2[A, USize](input.values(), Range(0, input.size())) do
      _Worker[A, B](v, f, i, hop)
    end

actor _Worker[A: Any val, B: Any val]
  be apply(v: A, f: {(A): B^} val, i: USize, hop: _Hopper[B] tag) =>
    hop.store(f(v), i)

actor _Hopper[B: Any val]
  let _cb: {(List[B] val, List[USize] val)} val
  let _results: Array[(B | None)]
  let _indexes: List[USize] = List[USize]

  new create(cb: {(List[B] val, List[USize] val)} val, c: USize) =>
    _cb = cb
    _results = Array[(B | None)]
    _results.concat(Iter[None](Repeat[None](None)).take(c))

  be store(v: B, i: USize) =>
    try
      _results(i) = v
      _indexes.push(i)
    end
    if (_indexes.size() == _results.size()) then
      let res_list: List[B] iso = recover List[B] end
      let idx_list: List[USize] iso = recover List[USize] end
      for (r, ix) in Zip2[(B | None), USize](_results.values(), _indexes.values()) do
        try res_list.push(r as B) end
        idx_list.push(ix)
      end
      _cb(consume res_list, consume idx_list)
    end
