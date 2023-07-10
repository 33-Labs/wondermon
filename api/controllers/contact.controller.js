const createError = require('http-errors');
const ContactService = require('../services/contact.service');

class ContactController {

    static isValidFlowAddress = (address) => {
      if (!address.startsWith("0x") || address.length != 18) {
        return false
      }
    
      const bytes = Buffer.from(address.replace("0x", ""), "hex")
      if (bytes.length != 8) { return false }
      return true
    }

    static create = async (req, res, next) => {
        try {
            const { name, address } = req.body
            if (!name || !address || !this.isValidFlowAddress(address)) {
              throw {statusCode: 422, message: "invalid params"}
            }

            const user = req.user.payload
            const contact = await ContactService.create(user, req.body)

            res.status(200).json({
                status: 0,
                message: 'success',
                data: contact
            })
        }
        catch (e) {
            console.log(e)
            next(createError(e.statusCode, e.message))
        }
    }

    static delete = async (req, res, next) => {
         try {
            const user = req.user.payload
            const contactId = parseInt(req.params.id)
            await ContactService.delete(user, contactId)
            res.status(200).json({
                status: 0,
                message: "success"
            })
        } catch (e) {
            next(createError(e.statusCode, e.message))
        }
    }

    static all = async (req, res, next) => {
        try {
            const user = req.user.payload
            const contacts = await ContactService.all(user);
            res.status(200).json({
                status: 0,
                message: 'success',
                data: contacts
            })
        } catch (e) {
            next(createError(e.statusCode, e.message))
        }
    }
}

module.exports = ContactController