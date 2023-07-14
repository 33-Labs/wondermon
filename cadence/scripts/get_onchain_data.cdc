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