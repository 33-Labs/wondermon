import Flovatar from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import MetadataViews from 0x1d7e57aa55817448

pub struct FlobitItem {
  pub let id: UInt64
  pub let display: MetadataViews.Display

  init(id: UInt64, display: MetadataViews.Display) {
    self.id = id
    self.display = display
  }
}

pub struct FlovatarItem {
  pub let id: UInt64
  pub let display: MetadataViews.Display

  init(id: UInt64, display: MetadataViews.Display) {
    self.id = id
    self.display = display
  }
}

pub struct StoreItems {
  pub let flovatars: [FlovatarItem]
  pub let flobits: [FlobitItem]

  init(flovatars: [FlovatarItem], flobits: [FlobitItem]) {
    self.flovatars = flovatars
    self.flobits = flobits
  }
}

pub fun main(address: Address): StoreItems {
    let account = getAccount(address)
    let flobitCap = account
      .getCapability(FlovatarComponent.CollectionPublicPath)
      .borrow<&{FlovatarComponent.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Flobit collection")

    let flobits: [FlobitItem] = []
    let flobitIds = flobitCap.getIDs()
    for tokenId in flobitIds {
      let resolver = flobitCap.borrowViewResolver(id: tokenId)
      if let display = MetadataViews.getDisplay(resolver) {
        flobits.append(FlobitItem(id: tokenId, display: display))
      }
    }

    let flovatarCap = account
      .getCapability(Flovatar.CollectionPublicPath)
      .borrow<&{Flovatar.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Flovatar collection")

    let flovatars: [FlovatarItem] = []
    let flovatarIds = flovatarCap.getIDs()
    for tokenId in flovatarIds {
      let resolver = flovatarCap.borrowViewResolver(id: tokenId)
      if let display = MetadataViews.getDisplay(resolver) {
        flovatars.append(FlovatarItem(id: tokenId, display: display))
      }
    }

    return StoreItems(flovatars: flovatars, flobits: flobits)
}