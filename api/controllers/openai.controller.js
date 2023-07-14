const ContactService = require('../services/contact.service');
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
      const messages = rawMessages.map(message => {
        return JSON.parse(message)
      })
      console.log("rawMessages", rawMessages)
      const onchainData = await FlowService.getOnchainInfo(flowAddress, flovatarId)
      const promptTemplate = await FlowService.getTemplate(flovatarId)
      const contacts = await ContactService.all(user)
      const aiMessage = await OpenaiService.chat(messages, req.body.prompt, onchainData, contacts, promptTemplate);
      console.log("aiMessage", aiMessage)
      if (aiMessage) {
        const {message, txid, command} = await this.executeCommand(aiMessage, onchainData, contacts, user, flovatarId);
        res.status(200).json({
          status: 0,
          message: 'success',
          data: {
            message: message,
            txid: txid,
            command: command
          },
        });
      } else {
        res.status(500).json({
          status: 1,
          message: 'failed to chat with NFT'
        });
      }
    } catch (e) {
      console.log(e);
      next(createError.InternalServerError(e.message));
    }
  }

  static async executeCommand(aiMessage, onchainData, contacts, user, flovatarId) {
    const contactNames = contacts.map((c) => c.name)
    const name = onchainData.flovatarInfo.flovatarData.name || "Frank"
    const { message, command } = this.extractCommand(aiMessage.replace(`${name}: `, ''));
    console.log('\nmessage', message)
    console.log('\ncommand', command)
    if (command && command.action == 'set_flobit' && command.serial) {
      const flobitId = command.serial
      const flobitIds = onchainData.flovatarInfo.flobits.map((f) => f.id)
      if (flobitIds.includes(`${flobitId}`)) {
        const txid = await FlowService.setFlobit(user, flovatarId, flobitId)
        return {message: "Sure!", txid: txid, command: command}
      } else {
        const msg = "Oh, it seems like I don't have this flobit."
        return {message: msg, txid: null, command: command}
      }
    } else if (command && command.action == 'remove_flobit' && command.serial) {
      let wearingFlobits = {}
      if (onchainData.flovatarInfo.accessoryData) {
        wearingFlobits[`${onchainData.flovatarInfo.accessoryData.id}`] = "accessory"
      }
      if (onchainData.flovatarInfo.hatData) {
        wearingFlobits[`${onchainData.flovatarInfo.hatData.id}`] = "hat"
      }
      if (onchainData.flovatarInfo.eyeglassesData) {
        wearingFlobits[`${onchainData.flovatarInfo.eyeglassesData.id}`] = "eyeglasses"
      }
      if (onchainData.flovatarInfo.backgroundData) {
        wearingFlobits[`${onchainData.flovatarInfo.backgroundData.id}`] = "background"
      }
      let category = wearingFlobits[`${command.serial}`]
      if (category) {
        const txid = await FlowService.removeFlobit(user, flovatarId, category)
        return {message: "Okay!", txid: txid, command: command}
      } else {
        const msg = "Oh, it seems like I'm not wearing this flobit."
        return {message: msg, txid: null, command: command}
      }
    } else if (command 
      && command.action == 'send_token' 
      && (command.token.toUpperCase() == 'FLOW' || command.token.totoUpperCase() == 'LOPPY')
      && command.amount
      && command.recipient && contactNames.includes(command.recipient)) {
        console.log("SEND TOKEN: ", command)
        console.log("CONTACT NAMES: ", contactNames)
        return {message: message, txid: null, command: command}
    } else if (command && command.action == 'none') {
      return {message: message, txid: null, command: null}
    } else if (command && command.action == 'present') {
      return {message: message, txid: null, command: command}
    } else if (command) {
      return {message: "Sorry, I can't understand you", txid: null, command: null}
    } else {
      return {message: message, txid: null, command: null}
    }
  }

  static extractCommand(message) {
    const regex = /\[(.*?)\]/g;
    const matches = message.match(regex);
    
    let result = message;
    let command = null
    if (matches) {
      for (const match of matches) {
        command = match.replace(/\[(.*?)\]/, "$1");
        result = result.replace(match, "");
      }
    }

    if (command) {
      command = JSON.parse(`{${command}}`)
    }

    return {
      message: result.trim().replace(" .", ""),
      command: command
    }
  }
}

module.exports = OpenaiController