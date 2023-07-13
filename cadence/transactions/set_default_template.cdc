import WondermonFlovatarPromptTemplate from "../contracts/WondermonFlovatarPromptTemplate.cdc"

transaction(template: String) {

  let adminRef: &WondermonFlovatarPromptTemplate.Admin

  prepare(acct: AuthAccount) {
    self.adminRef = acct
      .borrow<&WondermonFlovatarPromptTemplate.Admin>(from: WondermonFlovatarPromptTemplate.AdminStoragePath)
      ?? panic("Could not borrow admin")
  }

  execute {
    self.adminRef.setDefaultTemplate(template)
  }
}