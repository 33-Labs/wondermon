const { PrismaClient, Prisma } = require('@prisma/client')
const prisma = new PrismaClient()

require('dotenv').config()
const createError = require('http-errors')

class ContactService {

    static async create(userData, data) {
        let user = await prisma.user.findUnique({
            where: { email: userData.email }
        })

        if (!user) {
            throw createError.NotFound('User not found')
        }
        const contact = await prisma.contact.create({
            data: {
                ...data,
                userId: user.id
            }
        })
        delete contact.userId

        return contact
    }

    static async delete(userData, contactId) {
        let user = await prisma.user.findUnique({
            where: { email: userData.email }
        })

        if (!user) {
            throw createError.NotFound('User not found')
        }

        let contact = await prisma.contact.findUnique({
            where: { id: contactId }
        })

        if (!contact) {
            throw createError.NotFound('Contact not found')
        }

        await prisma.contact.delete({
            where: {
                id: contactId
            }
        })
    }

    static async getFlowAddress(userData, contactName) {
        let user = await prisma.user.findUnique({
            where: { email: userData.email }
        })

        if (!user) {
            throw createError.NotFound('User not found')
        }

        let contact = await prisma.contact.findFirst({
            where: { name: contactName }
        })

        if (!contact) {
            throw createError.NotFound('Contact not found')
        }

        return contact.address
    }

    static async all(userData) {
        let user = await prisma.user.findUnique({
            where: { email: userData.email }
        })

        if (!user) {
            throw createError.NotFound('User not found')
        }

        const contacts = await prisma.contact.findMany({
            where: { userId: user.id }
        })
        const contactsWithoutUserId = contacts.map((contact) => {
            return this.exclude(contact, ["userId"])
        })

        return contactsWithoutUserId
    }

    static exclude(user, keys) {
      for (let key of keys) {
        delete user[key]
      }
      return user
    }
}

module.exports = ContactService;