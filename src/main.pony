use "collections"
use "itertools"
use "random"
use "time"
  
actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
