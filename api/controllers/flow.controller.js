const createError = require('http-errors');
const ContactService = require('../services/contact.service');
const FlowService = require('../services/flow.service');

class FlowController {

    static setPromptTemplate = async (req, res, next) => {
      try {
        const user = req.user.payload
        const flovatarId = req.body.flovatarId
        const rawTemplate = req.body.template
        if (!flovatarId || !rawTemplate) {
          throw {statusCode: 422, message: "invalid params"}
        }

        const template = btoa(rawTemplate)
        const txid = await FlowService.setPromptTemplate(user, flovatarId, template)

        res.status(200).json({
            status: 0,
            message: 'success',
            data: {
              txid: txid
            }
        })
      }
      catch (e) {
          console.log(e)
          next(createError(e.statusCode, e.message))
      }
    }

    static removePromptTemplate = async (req, res, next) => {
      try {
        const user = req.user.payload
        const flovatarId = req.body.flovatarId
        if (!flovatarId) {
          throw {statusCode: 422, message: "invalid params"}
        }

        const txid = await FlowService.removePromptTemplate(user, flovatarId)

        res.status(200).json({
            status: 0,
            message: 'success',
            data: {
              txid: txid
            }
        })
      }
      catch (e) {
          console.log(e)
          next(createError(e.statusCode, e.message))
      }
    }

    static sendToken = async (req, res, next) => {
        try {
          const user = req.user.payload
          const symbol = req.body.symbol
          const recipient = req.body.recipient
          const amount = req.body.amount

          const recipientAddress = await ContactService.getFlowAddress(user, recipient)
          const txid = await FlowService.sendToken(user, symbol, amount, recipientAddress)

          res.status(200).json({
              status: 0,
              message: 'success',
              data: {
                txid: txid
              }
          })
        }
        catch (e) {
            console.log(e)
            next(createError(e.statusCode, e.message))
        }
    }
}

module.exports = FlowController