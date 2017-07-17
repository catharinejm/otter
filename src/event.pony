use p = "collections/persistent"
use "time"

class val Event
  let _ts: MicroTime val
  let _body: String val

  new val create(body': String val) =>
    _ts = MicroTime.now()
    _body = body'

  fun ts(): this->MicroTime! =>
    _ts

  fun body(): this->String! =>
    _body

  fun bytes(): Array[U8] val^ =>
    recover
      let ary = Array[U8]
      ary.concat(_ts.string().array().values())
      ary.concat(_body.array().values())
      ary
     end
