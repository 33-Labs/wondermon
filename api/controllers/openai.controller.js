const OpenaiService = require('../services/openai.service')
const createError = require('http-errors');

class OpenaiController {
  static chat = async (req, res, next) => {
    try {
      // const message = new ChatMessage(req.body.message, 'Human')
      // console.log(message)
      const message = {name: 'Human', text: req.body.message, role: 'human'}
      const data = await OpenaiService.chat([], req.body.message);
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