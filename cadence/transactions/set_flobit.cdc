import Flovatar, FlovatarComponent from 0x921ea449dffec68a

transaction(flovatarId: UInt64, flobitsId: UInt64) {
  let flovatarCollection: &Flovatar.Collection
  let flovatarComponentCollection: &FlovatarComponent.Collection
  let flobitsNFT: @FlovatarComponent.NFT

  prepare(account: AuthAccount) {
    self.flovatarCollection = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)!
    self.flovatarComponentCollection = account.borrow<&FlovatarComponent.Collection>(from: FlovatarComponent.CollectionStoragePath)!
    self.flobitsNFT <- self.flovatarComponentCollection.withdraw(withdrawID: flobitsId) as! @FlovatarComponent.NFT
  }

  execute {
    let flovatar: &{Flovatar.Private} = self.flovatarCollection.borrowFlovatarPrivate(id: flovatarId)!
    let category = self.flobitsNFT.getCategory()
    var oldFlobits: @FlovatarComponent.NFT? <- nil
    if category == "hat" {
      oldFlobits <-! flovatar.setHat(component: <-self.flobitsNFT)
    } else if category == "eyeglasses" {
      oldFlobits <-! flovatar.setEyeglasses(component: <-self.flobitsNFT)
    } else if category == "background" {
      oldFlobits <-! flovatar.setBackground(component: <-self.flobitsNFT)
    } else if category == "accessory" {
      oldFlobits <-! flovatar.setAccessory(component: <-self.flobitsNFT)
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