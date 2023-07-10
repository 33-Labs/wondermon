const FlowService = require('../services/flow.service');
const OpenaiService = require('../services/openai.service')
const createError = require('http-errors');

class OpenaiController {
  static chat = async (req, res, next) => {
    try {
      const user = req.user.payload
      const flowAddress = user.flowAccount.address
      const flovatarId = req.body.flovatarId
      const rawMessages = req.body.messages || []
      console.log("rawMessages", rawMessages)
      const messages = rawMessages.map(message => {
        return JSON.parse(message)
      })
      console.log("messages", messages)
      const onchainData = await FlowService.getOnchainInfo(flowAddress, flovatarId)
      const aiMessage = await OpenaiService.chat(messages, req.body.prompt, onchainData);

      const {message, txid} = await this.executeCommand(aiMessage, onchainData, user, flovatarId);

      res.status(200).json({
        status: 0,
        message: 'success',
        data: {
          message: message,
          txid: txid
        },
      });
    } catch (e) {
      console.log(e);
      next(createError.InternalServerError(e.message));
    }
  }

  static async executeCommand(aiMessage, onchainData, user, flovatarId) {
    const { message, command } = this.extractCommand(aiMessage);
    console.log('\nmessage', message)
    console.log('\ncommand', command)
    if (command && command.action == 'set_flobit' && command.serial) {
      const flobitId = command.serial
      const flobitIds = onchainData.flobits.map((f) => f.id)
      console.log("flobitIds", flobitIds)
      if (flobitIds.includes(`${flobitId}`)) {
        const txid = await FlowService.setFlobit(user, flovatarId, flobitId)
        return {message: "Sure!", txid: txid}
      } else {
        const msg = "Oh, it seems like I don't have this flobit."
        return {message: msg, txid: null}
      }
    } else if (command && command.action == 'remove_flobit' && command.serial) {
      let wearingFlobits = {}
      if (onchainData.accessoryData) {
        wearingFlobits[`${onchainData.accessoryData.id}`] = "accessory"
      }
      if (onchainData.hatData) {
        wearingFlobits[`${onchainData.hatData.id}`] = "hat"
      }
      if (onchainData.eyeglassesData) {
        wearingFlobits[`${onchainData.eyeglassesData.id}`] = "eyeglasses"
      }
      if (onchainData.backgroundData) {
        wearingFlobits[`${onchainData.backgroundData.id}`] = "background"
      }
      console.log(wearingFlobits)
      let category = wearingFlobits[`${command.serial}`]
      if (category) {
        const txid = await FlowService.removeFlobit(user, flovatarId, category)
        return {message: "Okay!", txid: txid}
      } else {
        const msg = "Oh, it seems like I'm not wearing this flobit."
        return {message: msg, txid: null}
      }
    } else {
      return {message: message, txid: null}
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

    if (command) {
      command = JSON.parse(`{${command}}`)
    }

    return {
      message: result,
      command: command
    }
  }
}

module.exports = OpenaiController