import Flovatar from 0x921ea449dffec68a
pub struct BasicFlovatar {
    pub let name: String
    pub let svg: String

    init(name: String, svg: String) {
        self.name = name
        self.svg = svg
    }
}

pub fun main(address: Address, flovatarId: UInt64): BasicFlovatar {
  let account = getAuthAccount(address)

  let flovatarCap = account
    .getCapability(Flovatar.CollectionPublicPath)
    .borrow<&{Flovatar.CollectionPublic}>()
    ?? panic("Could not borrow flovatar public collection")

  let flovatar = flovatarCap.borrowFlovatar(id: flovatarId)
    ?? panic("Could not borrow flovatar with that ID from collection")

  let svg = flovatar.getSvg()
  let res = BasicFlovatar(name: flovatar.getName(), svg: svg)
  return res
}