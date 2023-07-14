import FlowToken from 0x1654653399040a61
import FungibleToken from 0xf233dcee88fe0abe

transaction(amount: UFix64, recipient: Address) {

  let vaultRef: &FlowToken.Vault
  let recipientRef: &{FungibleToken.Receiver}
  prepare(account: AuthAccount) {
    self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Could not borrow a reference to the owner's vault")
    self.recipientRef = getAccount(recipient)
        .getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        .borrow()
        ?? panic("Could not borrow a reference to the recipient's receiver")
  }

  execute {
    let vault <- self.vaultRef.withdraw(amount: amount)
    self.recipientRef.deposit(from: <-vault)
  }
}