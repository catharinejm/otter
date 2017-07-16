use "collections"
use "itertools"
use "random"
use "time"

class val ID
  let _id: U64
  new val create() =>
    (let sec, let nsec) = Time.now()
    let rand = Rand(sec.u64(), nsec.u64())
    _id = rand.u64()

class val Associate
  let _fname: String
  let _lname: String
  let _married: Bool
  let _age: U8

  new val create(fname': String, lname': String, married': Bool, age': U8) =>
    _fname = fname'
    _lname = lname'
    _married = married'
    _age = age'

  fun fname(): String => _fname
  fun lname(): String => _lname
  fun married(): Bool => _married
  fun age(): U8 => _age

interface tag ModelAction[Model: Any val]
  be apply(model: Model)
  be none()

class val Some[T: Any #share]
  let _t: T
  new val create(t': T) =>
    _t = t'
  fun get(): this->T =>
    _t

type Option[T: Any #share] is (Some[T] | None)

primitive Util
  fun map[T: Any #share, R: Any #share](opt: Option[T], f: {(T): R}): Option[R] =>
    match opt
      | None => None
      | let s: Some[T] => Some[R](f(s.get()))
    end

trait tag DataService[Model: Any val]
  fun ref _data(): MapIs[ID, Model]

  be insert(model: Model) =>
    _data()(ID) = model

  be get(id: ID, f: ModelAction[Model]) =>
    try f(_data()(id)) else f.none() end

  be delete(id: ID, f: Option[ModelAction[Model]] = None) =>
    let model =
      try
        (_, let m) = _data().remove(id)
        m
      end
    Util.map[Model, Option[None]](model, {(m: Model) => Util.map[{(Model)} val, None](f, {(f': {(Model)} val) => f'(m)})})

  be update(id: ID, model: Model, f: Option[ModelAction[Model]] = None) =>
    if _data().contains(id) then
      _data()(id) = model
    end

actor AssociateService is DataService[Associate]
  let _assocs: MapIs[ID, Associate] = MapIs[ID, Associate]

  fun ref _data(): MapIs[ID, Associate] =>
    _assocs
  
actor Main
  let _out: StdStream
  new create(env: Env) =>
    _out = env.out
