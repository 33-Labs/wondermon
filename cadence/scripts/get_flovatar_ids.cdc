import Flovatar from 0x921ea449dffec68a

pub fun main(address: Address): [UInt64] {
    let account = getAccount(address)
    let collection = account.getCapability(Flovatar.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()
        ?? panic("Could not borrow Flovatar collection")
    return collection.getIDs()
}