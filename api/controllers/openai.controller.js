const FlowService = require('../services/flow.service');
const OpenaiService = require('../services/openai.service')
const createError = require('http-errors');

class OpenaiController {
  static chat = async (req, res, next) => {
    try {
      // const message = new ChatMessage(req.body.message, 'Human')
      // console.log(message)
      // const prompt = {name: 'Human', text: req.body.message, role: 'human'}

      // const flowAddress = req.body.flowAddress
      const user = req.user.payload
      const flowAddress = user.flowAccount.address
      const flovatarId = req.body.flovatarId
      console.log(flowAddress, flovatarId)
      const messages = []
      const onchainData = await FlowService.getOnchainInfo(flowAddress, flovatarId)
      const data = await OpenaiService.chat(messages, req.body.prompt, onchainData);
      res.status(200).json({
        status: 0,
        message: 'success',
        data: data,
      });
    } catch (e) {
      console.log(e);
      next(createError.InternalServerError(e.message));
    }
  }
}

module.exports = OpenaiController