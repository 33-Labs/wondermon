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
      const aiMessage = await OpenaiService.chat(messages, req.body.prompt, onchainData);
      const { message, command } = this.extractCommand(aiMessage);

      this.executeCommand(command, onchainData);

      res.status(200).json({
        status: 0,
        message: 'success',
        data: message,
      });
    } catch (e) {
      console.log(e);
      next(createError.InternalServerError(e.message));
    }
  }

  static async executeCommand(command, onchainData) {
    if (command.action == 'change_flobits') {

    }
  }

  static extractCommand(message) {
    const regex = /(COMMAND: \[.*?\])/g;
    const matches = message.match(regex);
    
    let result = message;
    let command = null
    if (matches) {
      for (const match of matches) {
        command = match.replace(/COMMAND: \[(.*?)\]/, "$1");
        result = result.replace(match, "");
      }
    }

    return {
      message: result,
      command: command
    }
  }
}

module.exports = OpenaiController