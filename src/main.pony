use "collections"
use "itertools"

actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
