import WondermonFlovatarPromptTemplate from "../contracts.WondermonFlovatarPromptTemplate.cdc"

pub fun main(flovatarId: UInt64): String {
    return WondermonFlovatarPromptTemplate.getPromptTemplate(flovatarId: flovatarId)
}