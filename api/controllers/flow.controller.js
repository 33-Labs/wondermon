const flow = require('../services/flow.service')
const createError = require('http-errors');
const utils = require('../utils/flow')

class flowController {
    static account = async (req, res, next) => {
        try {
            let account = await flow.createWondermonAccount(req.user.payload)
            res.status(200).json({
                status: true,
                message: "Flow account is created",
                data: account
            })
        } catch (e) {
            console.log(e)
            next(createError(e.statusCode, e.message))
        }
    }
}

module.exports = flowController