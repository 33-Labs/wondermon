import Flovatar, FlovatarComponent from 0x921ea449dffec68a

transaction(flovatarId: UInt64, category: String) {

  let flovatarCollection: &Flovatar.Collection
  let flovatarComponentCollection: &FlovatarComponent.Collection

  prepare(account: AuthAccount) {
    self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
    self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
  }

  execute {
    let flovatar: &{Flovatar.Private} = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!
    var oldFlobits: @FlovatarComponent.NFT? <- nil
    if category == "hat" {
      oldFlobits <-! flovatar.removeHat()
    } else if category == "eyeglasses" {
      oldFlobits <-! flovatar.removeEyeglasses()
    } else if category == "background" {
      oldFlobits <-! flovatar.removeBackground()
    } else if category == "accessory" {
      oldFlobits <-! flovatar.removeAccessory()
    } else {
      panic("Invalid category")
    }

    if oldFlobits != nil {
        self.flovatarComponentCollection.deposit(token: <-oldFlobits!)
    } else {
        destroy oldFlobits
    }
  }
}