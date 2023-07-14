import Flovatar from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import MetadataViews from 0x1d7e57aa55817448

pub struct Flobit {
  pub let id: UInt64
  pub let display: MetadataViews.Display

  init(id: UInt64, display: MetadataViews.Display) {
    self.id = id
    self.display = display
  }
}

pub fun main(address: Address): [Flobit] {
    let account = getAccount(address)
    let flobitCap = account
      .getCapability(FlovatarComponent.CollectionPublicPath)
      .borrow<&{FlovatarComponent.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Flovatar collection")

    let res: [Flobit] = []
    let tokenIds = flobitCap.getIDs()
    for tokenId in tokenIds {
      let resolver = flobitCap.borrowViewResolver(id: tokenId)
      if let display = MetadataViews.getDisplay(resolver) {
        res.append(Flobit(id: tokenId, display: display))
      }
    }

    return res
}