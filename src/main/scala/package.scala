import java.nio.ByteBuffer
import java.security.{MessageDigest, SecureRandom}
import java.util.UUID

package object otter {
  type =/>:[-A, +B] = PartialFunction[A, B]

  type Bytes = Array[Byte]
  object Bytes {
    def apply(capacity: Int = 0): Array[Byte] = new Array[Byte](capacity)
  }

  implicit class BytesOps(private val bytes: Bytes) extends AnyVal {
    def md5: Bytes = {
      val md = MessageDigest.getInstance("MD5")
      md.update(bytes)
      md.digest
    }
  }

  implicit class UUIDOps(private val uuid: UUID) extends AnyVal {
    def bytes: Bytes = {
      val byteSize = java.lang.Long.BYTES * 2
      val buf = ByteBuffer.allocate(byteSize)
      buf.putLong(uuid.getMostSignificantBits)
      buf.putLong(uuid.getLeastSignificantBits)
      buf.flip()
      val ary = Bytes(byteSize)
      buf.get(ary)
      ary
    }
  }
}
