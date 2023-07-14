import SloppyStakes from 0x53f389d96fb4ce5e
import FungibleToken from 0xf233dcee88fe0abe

transaction(amount: UFix64, recipient: Address) {

  let vaultRef: &SloppyStakes.Vault
  let recipientRef: &{FungibleToken.Receiver}
  prepare(account: AuthAccount) {
    self.vaultRef = account.borrow<&SloppyStakes.Vault>(from: SloppyStakes.VaultStoragePath)
        ?? panic("Could not borrow a reference to the owner's vault")
    self.recipientRef = getAccount(recipient)
        .getCapability<&{FungibleToken.Receiver}>(SloppyStakes.ReceiverPublicPath)
        .borrow()
        ?? panic("Could not borrow a reference to the recipient's receiver")
  }

  execute {
    let vault <- self.vaultRef.withdraw(amount: amount)
    self.recipientRef.deposit(from: <-vault)
  }
}