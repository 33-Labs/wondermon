import WondermonFlovatarPromptTemplate from "../contracts/WondermonFlovatarPromptTemplate.cdc"

transaction(flovatarId: UInt64, template: String) {

  let adminRef: &WondermonFlovatarPromptTemplate.Admin

  prepare(acct: AuthAccount) {
    self.adminRef = acct
      .borrow<&WondermonFlovatarPromptTemplate.Admin>(from: WondermonFlovatarPromptTemplate.AdminStoragePath)
      ?? panic("Could not borrow admin")
  }

  execute {
    self.adminRef.setTemplate(flovatarId: flovatarId, template: template)
  }
}