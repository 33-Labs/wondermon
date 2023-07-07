const fcl = require('@onflow/fcl')
const utils = require('../utils/flow')
const { PrismaClient } = require('@prisma/client')
const createError = require('http-errors')
const prisma = new PrismaClient()
const CryptoJS = require("crypto-js");

require('dotenv').config()
utils.switchToMainnet()

const WondermonPath = "0xWondermon"
const WondermonAddress = process.env.ADMIN_ADDRESS

class FlowService {
  static encryptPrivateKey(key) {
    const secret = process.env.SECRET_PASSPHRASE
    const encrypted = CryptoJS.AES.encrypt(key, secret).toString()
    return encrypted
  }

  static decryptPrivateKey(encrypted) {
    const secret = process.env.SECRET_PASSPHRASE
    const decrypted = CryptoJS.AES.decrypt(encrypted, secret).toString(CryptoJS.enc.Utf8)
    return decrypted
  }

  static async getAdminAccountWithKeyIndex(keyIndex) {
    const FlowSigner = (await import('../utils/signer.mjs')).default
    const key = this.decryptPrivateKey(process.env.ADMIN_ENCRYPTED_PRIVATE_KEY)

    const signer = new FlowSigner(
      process.env.ADMIN_ADDRESS,
      key,
      keyIndex,
      {}
    )
    return signer
  }

  static async getUserSigner(flowAccount) {
    const FlowSigner = (await import('../utils/signer.mjs')).default
    const privateKey = this.decryptPrivateKey(flowAccount.encryptedPrivateKey)
    const signer = new FlowSigner(
      flowAccount.address,
      privateKey,
      0,
      {}
    )

    return signer
  }

  static generateKeypair() {
    const EC = require("elliptic").ec
    const ec = new EC("p256")

    let keypair = ec.genKeyPair()
    let privateKey = keypair.getPrivate().toString('hex')
    while (privateKey.length != 64) {
      keypair = ec.genKeyPair()
      privateKey = keypair.getPrivate().toString('hex')
    }

    const publicKey = keypair.getPublic().encode('hex').substring(2)
    return { privateKey: privateKey, publicKey: publicKey }
  }

  static AdminKeys = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false
  }

  static async getOnchainInfo(address, flovatarId) {
    let script = `
    import Flovatar from 0x921ea449dffec68a
    import FlovatarComponent from 0x921ea449dffec68a
    import FlovatarComponentTemplate from 0x921ea449dffec68a
    import MetadataViews from 0x1d7e57aa55817448
    
    pub struct FlobitData {
      pub let templateId: UInt64
      pub let rarity: String
      pub let name: String
      pub let description: String
      pub let category: String
      pub let color: String
    
      init(
        templateId: UInt64,
        rarity: String,
        name: String,
        description: String,
        category: String,
        color: String
      ) {
        self.templateId = templateId
        self.rarity = rarity
        self.name = name
        self.description = description
        self.category = category
        self.color = color
      }
    }
    
    pub struct FlovatarData {
      pub let id: UInt64
      pub let name: String
      pub let components: {String: UInt64}
      pub let accessoryId: UInt64?
      pub let hatId: UInt64?
      pub let eyeglassesId: UInt64?
      pub let backgroundId: UInt64?
      pub let bio: {String: String}
      init(
          id: UInt64,
          name: String,
          components: {String: UInt64},
          accessoryId: UInt64?,
          hatId: UInt64?,
          eyeglassesId: UInt64?,
          backgroundId: UInt64?,
          bio: {String: String}
          ) {
          self.id = id
          self.name = name
          self.components = components
          self.accessoryId = accessoryId
          self.hatId = hatId
          self.eyeglassesId = eyeglassesId
          self.backgroundId = backgroundId
          self.bio = bio
      }
    }
    
    pub struct FlovatarInfo {
      pub let flovatarData: FlovatarData
      pub let flovatarTraits: MetadataViews.Traits
      pub let accessoryData: FlobitData?
      pub let hatData: FlobitData?
      pub let eyeglassesData: FlobitData?
      pub let backgroundData: FlobitData?
      pub let flobits: [FlovatarComponent.ComponentData]
    
      init(
        flovatarData: FlovatarData, 
        flovatarTraits: MetadataViews.Traits,
        accessoryData: FlobitData?,
        hatData: FlobitData?,
        eyeglassesData: FlobitData?,
        backgroundData: FlobitData?,
        flobits: [FlovatarComponent.ComponentData]
      ) {
        self.flovatarData = flovatarData
        self.flovatarTraits = flovatarTraits
        self.accessoryData = accessoryData
        self.hatData = hatData
        self.eyeglassesData = eyeglassesData
        self.backgroundData = backgroundData
        self.flobits = flobits
      }
    }
    
    pub fun main(address: Address, flovatarId: UInt64): FlovatarInfo {
      let account = getAuthAccount(address)
    
      let flovatarCap = account
        .getCapability(Flovatar.CollectionPublicPath)
        .borrow<&{Flovatar.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow flovatar public collection")
    
      let resolver = flovatarCap.borrowViewResolver(id: flovatarId)
      let flovatarTraits = MetadataViews.getTraits(resolver)
        ?? panic("Could not borrow traits")
    
      let rawFlovatarData = Flovatar.getFlovatar(address: address, flovatarId: flovatarId)
        ?? panic("Could not borrow flovatar")
    
      let flovatarData = FlovatarData(
        id: rawFlovatarData.id,
        name: rawFlovatarData.name,
        components: rawFlovatarData.metadata.getComponents(),
        accessoryId: rawFlovatarData.accessoryId,
        hatId: rawFlovatarData.hatId,
        eyeglassesId: rawFlovatarData.eyeglassesId,
        backgroundId: rawFlovatarData.backgroundId,
        bio: rawFlovatarData.bio
      ) 
    
      var accessoryData: FlobitData? = nil
      if let accessoryId = flovatarData.accessoryId {
        if let accessoryTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: accessoryId) {
          accessoryData = FlobitData(
            templateId: accessoryTemplateData.id,
            rarity: accessoryTemplateData.rarity,
            name: accessoryTemplateData.name,
            description: accessoryTemplateData.description,
            category: accessoryTemplateData.category,
            color: accessoryTemplateData.color
          )
        }
      }
    
      var hatData: FlobitData? = nil
      if let hatId = flovatarData.hatId {
        if let hatTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: hatId) {
          hatData = FlobitData(
            templateId: hatTemplateData.id,
            rarity: hatTemplateData.rarity,
            name: hatTemplateData.name,
            description: hatTemplateData.description,
            category: hatTemplateData.category,
            color: hatTemplateData.color
          )
        }
      }
    
      var eyeglassesData: FlobitData? = nil
      if let eyeglassesId = flovatarData.eyeglassesId {
        if let eyeglassesTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: eyeglassesId) {
          eyeglassesData = FlobitData(
            templateId: eyeglassesTemplateData.id,
            rarity: eyeglassesTemplateData.rarity,
            name: eyeglassesTemplateData.name,
            description: eyeglassesTemplateData.description,
            category: eyeglassesTemplateData.category,
            color: eyeglassesTemplateData.color
          )
        }
      }
    
      var backgroundData: FlobitData? = nil
      if let backgroundId = flovatarData.backgroundId {
        if let backgroundTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: backgroundId) {
          backgroundData = FlobitData(
            templateId: backgroundTemplateData.id,
            rarity: backgroundTemplateData.rarity,
            name: backgroundTemplateData.name,
            description: backgroundTemplateData.description,
            category: backgroundTemplateData.category,
            color: backgroundTemplateData.color
          )
        }
      }
      
      let flobits = FlovatarComponent.getComponents(address: address)
    
      let flovatarInfo = FlovatarInfo(
        flovatarData: flovatarData,
        flovatarTraits: flovatarTraits,
        accessoryData: accessoryData,
        hatData: hatData,
        eyeglassesData: eyeglassesData,
        backgroundData: backgroundData,
        flobits: flobits
      )
    
      return flovatarInfo
    }
    `
    const onChainInfo = await fcl.query({
      cadence: script,
      args: (arg, t) => [
        arg(address, t.Address),
        arg(flovatarId, t.UInt64)
      ]
    })

    onChainInfo.flovatarTraits.traits.map((t) => console.log(t))
    return onChainInfo
  }

  static async generateFlowAccounts() {
    const accounts = await prisma.flowAccount.findMany({
      where: { userId: null }
    })

    if (accounts.length < 5) {
      let keyIndex = null
      for (const [key, value] of Object.entries(this.AdminKeys)) {
        if (value == false) {
          keyIndex = parseInt(key)
          break
        }
      }

      if (keyIndex == null) {
        return
      }

      this.AdminKeys[keyIndex] = true
      const signer = await this.getAdminAccountWithKeyIndex(keyIndex)
      const { privateKey: privateKey, publicKey: publicKeyHex } = this.generateKeypair()
      const code = this.getAccountCreationCode()
      try {
        const txid = await signer.sendTransaction(code, (arg, t) => [
          arg("Wondermon", t.String),
          arg(publicKeyHex, t.String)
        ])

        if (txid) {
          let tx = await fcl.tx(txid).onceSealed()
          this.AdminKeys[keyIndex] = false
          let event = tx.events.find((e) => e.type == 'flow.AccountCreated')
          if (!event) {
            console.log("Account prepare failed")
            return
          }

          const address = event.data.address
          await prisma.flowAccount.create({
            data: {
              address: address,
              encryptedPrivateKey: this.encryptPrivateKey(privateKey)
            }
          })
          console.log("Account generated:", address)
        }
      } catch (e) {
        this.AdminKeys[keyIndex] = false
        console.log(e)
        return
      }
    }
  }

  static async setGeneratorIndex() {
    const users = await prisma.user.findMany({
      where: { flowAccount: null, generatorIndex: null }
    })

    for (let i = 0; i < users.length; i++) {
      const user = users[i]
      const indicies = Object.keys(this.AdminKeys)
      const index = user.id % indicies.length
      try {
        await prisma.user.update({
          where: { email: user.email },
          data: { generatorIndex: index }
        }) 
      } catch (e) {
        console.log(e)
      }
    } 
  }

  static async generateWondermonAccounts() {
    await this.setGeneratorIndex()
    const indicies = Object.keys(this.AdminKeys) 
    for (let i = 0; i < indicies.length; i++) {
      let index = indicies[i]
      if (this.AdminKeys[index] == false) {
        this.generateWondermonAccountsWithKey(index)
      }
    }
  }

  static async generateWondermonAccountsWithKey(_keyIndex) {
    if (this.AdminKeys[_keyIndex] == true) {
      return
    }
    this.AdminKeys[_keyIndex] = true
    const keyIndex = parseInt(_keyIndex)
    const users = await prisma.user.findMany({
      where: { flowAccount: null, generatorIndex: keyIndex }
    })
    
    for (let i = 0; i < users.length; i++) {
      let user = users[i]
      try {
        console.log(`[${user.name}] Generating address with key #${keyIndex}`)
        await this.createWondermonAccount(user, keyIndex)
        console.log(`[${user.name}] Address is generated with key #${keyIndex}`)
      } catch (e) {
        console.log(e)
      }
    }

    this.AdminKeys[_keyIndex] = false
  }

  static async createWondermonAccount(data, keyIndex) {
    const { name, email } = data
    const user = await prisma.user.findUnique({
      where: { email },
      include: { flowAccount: true }
    })

    if (!user) {
      throw createError.NotFound('User not found')
    }

    if (user.flowAccount) {
      delete user.flowAccount.id
      delete user.flowAccount.encryptedPrivateKey
      delete user.flowAccount.userId
      return user.flowAccount
    }

    const signer = await this.getAdminAccountWithKeyIndex(keyIndex)
    const { privateKey: privateKey, publicKey: publicKeyHex } = this.generateKeypair()
    const code = this.getAccountCreationCode()

    try {
      const txid = await signer.sendTransaction(code, (arg, t) => [
        arg(name, t.String),
        arg(publicKeyHex, t.String)
      ])

      if (txid) {
        let tx = await fcl.tx(txid).onceSealed()
        let event = tx.events.find((e) => e.type == 'flow.AccountCreated')
        if (!event) {
          throw { statusCode: 500, message: "Account generation failed" }
        }
        const address = event.data.address
        let flowAccount = await prisma.$transaction(async (tx) => {
          let user = await tx.user.update({
            where: { email: email }
          })

          let flowAccount = await tx.flowAccount.create({
            data: {
              address: address,
              encryptedPrivateKey: this.encryptPrivateKey(privateKey),
              userId: user.id
            }
          })

          return flowAccount
        })

        delete flowAccount.id
        delete flowAccount.encryptedPrivateKey
        delete flowAccount.userId
        delete flowAccount.createdAt
        delete flowAccount.updatedAt

        return flowAccount
      }
      throw "send transaction failed"
    } catch (e) {
      throw { statusCode: 500, message: `Account generation failed ${e}` }
    }
  }

  static getAccountCreationCode() {
    const code = `
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
    `
      .replaceAll(WondermonPath, WondermonAddress)

    return code
  }
}

module.exports = FlowService