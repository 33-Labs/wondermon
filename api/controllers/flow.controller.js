const createError = require('http-errors');
const ContactService = require('../services/contact.service');
const FlowService = require('../services/flow.service');

class FlowController {

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