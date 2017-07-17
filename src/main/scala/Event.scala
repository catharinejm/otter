package otter

import java.util.UUID

case class Event(id: UUID, body: String) {
  def bytes: Bytes = {
    id.bytes ++ body.getBytes
  }

}
