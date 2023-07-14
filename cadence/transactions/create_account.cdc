import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import FlowToken from 0x1654653399040a61
import MetadataViews from 0x1d7e57aa55817448
import Flovatar from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import SloppyStakes from 0x53f389d96fb4ce5e

transaction(name: String, publicKeyHex: String) {
    prepare(signer: AuthAccount) {
        let account = AuthAccount(payer: signer)
        let key = PublicKey(
          publicKey: publicKeyHex.decodeHex(),
          signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )

        account.keys.add(
          publicKey: key,
          hashAlgorithm: HashAlgorithm.SHA3_256,
          weight: 1000.0
        )

        let initialFundingAmt = 0.005
        if initialFundingAmt > 0.0 {
          // Get a vault to fund the new account
          let fundingProvider = signer.borrow<&FlowToken.Vault{FungibleToken.Provider}>(
                  from: /storage/flowTokenVault
              )!
          // Fund the new account with the initialFundingAmount specified
          account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
              .borrow()!
              .deposit(
                  from: <-fundingProvider.withdraw(
                      amount: initialFundingAmt
                  )
              )
        }

        // setup Flovatar collection
        account.save(<-Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)
        account.unlink(Flovatar.CollectionPublicPath)
        account.link<&Flovatar.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)

        // setup FlovatarComponent collection
        account.save(<- FlovatarComponent.createEmptyCollection(), to: FlovatarComponent.CollectionStoragePath)
        account.unlink(FlovatarComponent.CollectionPublicPath)
        account.link<&FlovatarComponent.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionPublicPath, target: FlovatarComponent.CollectionStoragePath) 

        // setup LOPPY token
        if signer.borrow<&FungibleToken.Vault>(from: /storage/SloppyStakesVault) == nil {
          signer.save(<- SloppyStakes.createEmptyVault(), to: /storage/SloppyStakesVault)
          signer.link<&SloppyStakes.Vault{FungibleToken.Balance}>(/public/SloppyStakesMetadata, target: /storage/SloppyStakesVault)
          signer.link<&SloppyStakes.Vault{FungibleToken.Receiver}>(/public/SloppyStakesReceiver, target: /storage/SloppyStakesVault)
        }
    }
}