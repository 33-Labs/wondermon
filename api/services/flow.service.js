const fcl = require('@onflow/fcl')
const utils = require('../utils/flow')
const { PrismaClient } = require('@prisma/client')
const createError = require('http-errors')
const prisma = new PrismaClient()
const CryptoJS = require("crypto-js");
const Decimal = require('decimal.js')

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



  static async sendToken(userData, symbol, amount, recipient) {
    const { email } = userData
    const user = await prisma.user.findUnique({
      where: { email },
      include: { flowAccount: true }
    })

    if (!user) {
      throw createError.NotFound('User not found')
    }

    if (!user.flowAccount) {
      throw createError.NotFound('flow account not found')
    } 

    let signer = await this.getUserSigner(user.flowAccount)
    let code = this.getSendTokenCode(symbol)
    let amt = new Decimal(amount).toFixed(8).toString()
    try {
      const txid = await signer.sendTransaction(code, (arg, t) => [
        arg(`${amt}`, t.UFix64),
        arg(`${recipient}`, t.Address),
      ])

      return txid
    } catch (e) {
      throw { statusCode: 500, message: `send token failed ${e}` }
    }
  }

  static getSendTokenCode(tokenSymbol) {
    let symbol = tokenSymbol.toUpperCase()
    if (symbol == 'FLOW') {
      return `
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
      }`
    } else if (symbol == 'LOPPY') {
      return `
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
      }`
    } else {
      return ''
    }
  }

  static async setFlobit(userData, flovatarId, flobitId) {
    const { email } = userData
    const user = await prisma.user.findUnique({
      where: { email },
      include: { flowAccount: true }
    })

    if (!user) {
      throw createError.NotFound('User not found')
    }

    if (!user.flowAccount) {
      throw createError.NotFound('flow account not found')
    }

    let signer = await this.getUserSigner(user.flowAccount)
    let code = `
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
    `

    try {
      const txid = await signer.sendTransaction(code, (arg, t) => [
        arg(`${flovatarId}`, t.UInt64),
        arg(`${flobitId}`, t.UInt64),
      ])

      return txid
    } catch (e) {
      throw { statusCode: 500, message: `set flobit failed ${e}` }
    }
  }

  static async removeFlobit(userData, flovatarId, category) {
    const { email } = userData
    const user = await prisma.user.findUnique({
      where: { email },
      include: { flowAccount: true }
    })

    if (!user) {
      throw createError.NotFound('User not found')
    }

    if (!user.flowAccount) {
      throw createError.NotFound('flow account not found')
    }

    let signer = await this.getUserSigner(user.flowAccount)
    let code = `
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
    `

    try {
      const txid = await signer.sendTransaction(code, (arg, t) => [
        arg(`${flovatarId}`, t.UInt64),
        arg(`${category}`, t.String),
      ])

      return txid
    } catch (e) {
      throw { statusCode: 500, message: `remove flobit failed ${e}` }
    }
  }

  static async getTemplate(flovatarId) {
    let script = `
    import WondermonFlovatarPromptTemplate from 0x504dadc2410ae4f6

    pub fun main(flovatarId: UInt64): String {
        return WondermonFlovatarPromptTemplate.getPromptTemplate(flovatarId: flovatarId)
    }
    `

    const b64Template = await fcl.query({
      cadence: script,
      args: (arg, t) => [
        arg(`${flovatarId}`, t.UInt64)
      ]
    })
    const template = atob(b64Template)

    return template
  }

  static async getOnchainInfo(address, flovatarId) {
    let script = `
    import Flovatar from 0x921ea449dffec68a
    import FlovatarComponent from 0x921ea449dffec68a
    import FlovatarComponentTemplate from 0x921ea449dffec68a
    import MetadataViews from 0x1d7e57aa55817448
    
    import FlowToken from 0x1654653399040a61
    import SloppyStakes from 0x53f389d96fb4ce5e
    import FungibleToken from 0xf233dcee88fe0abe
    
    import SwapPair from 0xbfb26bb8adf90399
    import SwapConfig from 0xb78ef7afa52ff906
    import SwapInterfaces from 0xb78ef7afa52ff906
    
    pub struct FlobitData {
      pub let id: UInt64
      pub let templateId: UInt64
      pub let rarity: String
      pub let name: String
      pub let description: String
      pub let category: String
      pub let color: String
    
      init(
        id: UInt64,
        templateId: UInt64,
        rarity: String,
        name: String,
        description: String,
        category: String,
        color: String
      ) {
        self.id = id
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
    
    pub struct TokensInfo {
      pub let flowBalance: UFix64
      pub let loppyBalance: UFix64
      pub let availableFlowBalance: UFix64
      pub let availableLoppyBalance: UFix64
      pub let flowToLoppyPrice: UFix64
      pub let loppyToFlowPrice: UFix64
    
      init(
        flowBalance: UFix64,
        loppyBalance: UFix64,
        flowToLoppyPrice: UFix64,
        loppyToFlowPrice: UFix64
      ) {
        self.flowBalance = flowBalance
        self.loppyBalance = loppyBalance
        self.availableFlowBalance = flowBalance - 1.0 > 0.0 ? flowBalance - 1.0 : 0.0
        self.availableLoppyBalance = loppyBalance
        self.flowToLoppyPrice = flowToLoppyPrice
        self.loppyToFlowPrice = loppyToFlowPrice
      }
    }
    
    pub struct OnchainData {
      pub let flovatarInfo: FlovatarInfo
      pub let tokensInfo: TokensInfo
    
      init(
        flovatarInfo: FlovatarInfo,
        tokensInfo: TokensInfo
      ) {
        self.flovatarInfo = flovatarInfo
        self.tokensInfo = tokensInfo
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
    
    pub fun main(address: Address, flovatarId: UInt64): OnchainData {
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
    
      let flovatarCollectionRef = account.borrow<&Flovatar.Collection>(from: Flovatar.CollectionStoragePath)
        ?? panic("Could not borrow flovatar collection reference")
    
      let flovatarPrivate = flovatarCollectionRef.borrowFlovatarPrivate(id: flovatarId)
        ?? panic("Could not borrow flovatar private")
    
      var accessoryData: FlobitData? = nil
      if let accessoryId = flovatarData.accessoryId {
        var flobitId: UInt64 = 0
        if let oldFlobit <- flovatarPrivate.removeAccessory() {
          let ref = &oldFlobit as &FlovatarComponent.NFT
          flobitId = ref.id
          destroy oldFlobit
        }
    
        if let accessoryTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: accessoryId) {
          accessoryData = FlobitData(
            id: flobitId,
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
        var flobitId: UInt64 = 0
        if let oldFlobit <- flovatarPrivate.removeHat() {
          let ref = &oldFlobit as &FlovatarComponent.NFT
          flobitId = ref.id
          destroy oldFlobit
        }
    
        if let hatTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: hatId) {
          hatData = FlobitData(
            id: flobitId,
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
        var flobitId: UInt64 = 0
        if let oldFlobit <- flovatarPrivate.removeEyeglasses() {
          let ref = &oldFlobit as &FlovatarComponent.NFT
          flobitId = ref.id
          destroy oldFlobit
        }
    
        if let eyeglassesTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: eyeglassesId) {
          eyeglassesData = FlobitData(
            id: flobitId,
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
        var flobitId: UInt64 = 0
        if let oldFlobit <- flovatarPrivate.removeBackground() {
          let ref = &oldFlobit as &FlovatarComponent.NFT
          flobitId = ref.id
          destroy oldFlobit
        }
    
        if let backgroundTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: backgroundId) {
          backgroundData = FlobitData(
            id: flobitId,
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
    
      var flowBalance: UFix64 = 0.0
      let flowCap = account.getCapability<&FlowToken.Vault{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()
      if let flow = flowCap {
        flowBalance = flow.balance
      }
    
      let loppyBalance = SloppyStakes.getBalance(address: address)
    
      let pairAccount = getAccount(0xbfb26bb8adf90399)
      let pair = pairAccount
        .getCapability<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath)
        .borrow()
        ?? panic("Could not borrow pair")
      let loppyToFlow = pair.getAmountOut(amountIn: 1.0, tokenInKey: "A.1654653399040a61.FlowToken")
      let flowToLoppy = pair.getAmountOut(amountIn: 1.0, tokenInKey: "A.53f389d96fb4ce5e.SloppyStakes")
    
      let tokensInfo = TokensInfo(
        flowBalance: flowBalance,
        loppyBalance: loppyBalance,
        flowToLoppyPrice: flowToLoppy,
        loppyToFlowPrice: loppyToFlow
      )
    
      return OnchainData(
        flovatarInfo: flovatarInfo,
        tokensInfo: tokensInfo
      )
    }
    `
    const onChainInfo = await fcl.query({
      cadence: script,
      args: (arg, t) => [
        arg(address, t.Address),
        arg(`${flovatarId}`, t.UInt64)
      ]
    })

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