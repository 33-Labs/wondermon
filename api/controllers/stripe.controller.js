const createError = require('http-errors');
const StripeService = require('../services/stripe.service')

class StripeController {
  static createCheckoutSession = async (req, res, next) => {
    try {
      if (!req.body.tokenId || !req.body.itemType) {
        res.status(422).json({
          status: 1,
          message: "invalid params"
        })
        return
      }
      const itemType = req.body.itemType
      const tokenId = parseInt(`${req.body.tokenId}`)
      console.log(itemType, tokenId)

      const data = await StripeService.createCheckoutSession(req.user.payload, itemType, tokenId)
      res.status(200).json({
        status: 0,
        message: "",
        data: data
      })
    }
    catch (e) {
        console.log(e)
        next(createError(e.statusCode, e.message))
    }
  }
}

module.exports = StripeController