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

class flowService {
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
        }
    }
    `
      .replaceAll(WondermonPath, WondermonAddress)

    return code
  }
}

module.exports = flowService