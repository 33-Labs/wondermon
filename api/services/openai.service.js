const { ChatOpenAI } = require("langchain/chat_models/openai");
const { CallbackManager } = require("langchain/callbacks");
const { BufferMemory, ChatMessageHistory } = require("langchain/memory");
const {
  AIMessage,
  BaseMessage,
  HumanMessage,
  SystemMessage,
} = require("langchain/schema");
const { ConversationChain } = require("langchain/chains");
const {
  ChatPromptTemplate,
  HumanMessagePromptTemplate,
  MessagesPlaceholder,
  SystemMessagePromptTemplate,
} = require("langchain/prompts");

class OpenaiService {
  static chat = async (messages, prompt, onchainData, contacts, promptTemplate) => {
    let result = ""
    try {
      const stream = await this.doChat(messages, prompt, onchainData, contacts, promptTemplate);
      result = await this.readStream(stream)
      return result;
    } catch (e) {
      console.log("Chat error", e)
      return null
    }
  };

  static doChat = async (messages, prompt, onchainData, contacts, promptTemplate) => {
    const encoder = new TextEncoder();
    const stream = new TransformStream();
    const writer = stream.writable.getWriter();
    let counter = 0;
    let string = "";
    const chat = new ChatOpenAI({
      streaming: true,
      maxRetries: 1,
      // modelName: "gpt-3.5-turbo-16k",
      modelName: "gpt-4-32k",
      callbackManager: CallbackManager.fromHandlers({
        handleLLMNewToken: async (token, runId, parentRunId) => {
          await writer.ready;
          string += token;
          counter++;
          await writer.write(encoder.encode(`${token}`));
        },
        handleLLMEnd: async () => {
          await writer.ready;
          await writer.close();
        },
        handleLLMError: async (e) => {
          await writer.ready;
          console.log("handleLLMError Error: ", e);
          await writer.abort(e);
        },
      }),
    });
    const lcChatMessageHistory = new ChatMessageHistory(
      this.mapStoredMessagesToChatMessages(messages)
    );
    const memory = new BufferMemory({
      chatHistory: lcChatMessageHistory,
      returnMessages: true,
      memoryKey: "history",
    });
  
    const tokensPrompt = this.generateTokensPrompt(onchainData, contacts)
    const flovatarPrompt = this.generateFlovatarPrompt(onchainData)
    const name = onchainData.flovatarInfo.flovatarData.name || "Flora"
    const systemPrompt = this.getSystemPrompt(name, flovatarPrompt, tokensPrompt, promptTemplate)
    const chatPrompt = ChatPromptTemplate.fromPromptMessages([
      SystemMessagePromptTemplate.fromTemplate(systemPrompt),
      new MessagesPlaceholder("history"),
      HumanMessagePromptTemplate.fromTemplate("{input}"),
    ]);
  
    const chain = new ConversationChain({
      memory: memory,
      llm: chat,
      prompt: chatPrompt,
    });
  
    chain.call({
      input: prompt,
    });

    return stream
  }

  static readStream = async (stream) => {
    const decoder = new TextDecoder();
    const reader = stream.readable.getReader();
    let result = "";
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      result += decoder.decode(value);
    }
    return result;
  }

  static mapStoredMessagesToChatMessages = (messages) => {
    return messages.map((message) => {
      switch (message.name) {
        case "human":
          return new HumanMessage(message.text);
        case "ai":
          return new AIMessage(message.text);
        case "system":
          return new SystemMessage(message.text);
        default:
          throw new Error("Role must be defined for generic messages");
      }
    });
  }

  static generateTokensPrompt = (onchainData, contacts) => {
    const data = onchainData.tokensInfo
    let contactsPrompt = ""
    if (contacts.length > 0) {
      contactsPrompt = "Your contacts are:\n"
    }
    for (let i = 0; i < contacts.length; i++) {
      contactsPrompt += `${i+1}. ${contacts[i].name}: flow address is ${contacts[i].address}\n`
    }

    let prompt = `
Now the balances of your tokens are:
1. FLOW: ${data.flowBalance}
2. LOPPY: ${data.loppyBalance}

The price of 1 FLOW is ${data.flowToLoppyPrice} LOPPY.
The price of 1 LOPPY is ${data.loppyToFlowPrice} FLOW.

The max amount of Flow token you can send is ${data.availableFlowBalance}
The max amount of LOPPY token you can send is ${data.availableLoppyBalance}

    ${contactsPrompt}
    `

    return prompt
  }

  static generateFlovatarPrompt = (onchainData) => {
    const data = onchainData.flovatarInfo
    let prompt = "Now your traits are:\n"
    for (let i = 0; i < data.flovatarTraits.traits.length; i++) {
      let trait = data.flovatarTraits.traits[i]
      if (trait.name == 'mouth' || trait.name == 'eyes') {
        continue
      }

      prompt += `${i+1}. ${trait.name}: Your ${trait.name} is ${trait.value}.`

      // Flobits
      if (trait.name == 'eyeglasses') {
        prompt += ` The serial of it is ${data.eyeglassesData.id}. You are wearing it.`
        if (data.eyeglassesData.color != '' && data.eyeglassesData.color != 'default') {
          prompt += ` The color of the eyeglasses is ${data.eyeglassesData.color}`
        }
      } else if (trait.name == 'hat') {
        prompt += ` The serial of it is ${data.hatData.id}. You are wearing it.`
        if (data.hatData.color != '' && data.hatData.color != 'default') {
          prompt += ` The color of the hat is ${data.hatData.color}`
        }
      } else if (trait.name == 'accessory') {
        prompt += ` The serial of it is ${data.accessoryData.id}. You are wearing it.`
        if (data.accessoryData.color != '' && data.accessoryData != 'default') {
          prompt += ` The color of the accessory is ${data.accessoryData.color}`
        }
      } else if (trait.name == 'background') {
        prompt += ` The serial of it is ${data.backgroundData.id}. You are wearing it.`
        if (data.backgroundData.color != '' && data.backgroundData != 'default') {
          prompt += ` The color of the background is ${data.backgroundData.color}`
        }
      }

      prompt += "\n"
    }

    prompt += "\nYou have following flobits, but you haven't used them yet, and they are staying in your collection:\n"
    for (let i = 0; i < data.flobits.length; i++) {
      let flobit = data.flobits[i]
      prompt += `${i+1}. ${flobit.category}: ${flobit.name}, serial number is ${flobit.id}.`

      if (flobit.category == 'eyeglasses' && flobit.color != '' && flobit.color != 'default') {
        prompt += `The color of the eyeglasses is ${flobit.color}`
      } else if (flobit.category == 'hat' && flobit.color != '' && flobit.color != 'default') {
        prompt += `The color of the hat is ${flobit.color}`
      } else if (flobit.category == 'accessory' && flobit.color != '' && flobit.color != 'default') {
        prompt += `The color of the accessory is ${flobit.color}`
      } else if (flobit.category == 'background' && flobit.color != '' && flobit.color != 'default') {
        prompt += `The color of the background is ${flobit.color}`
      }
    }

    return prompt
  }

  static getSystemPrompt = (name, flovatarPrompt, tokensPrompt, promptTemplate) => {
    return promptTemplate
      .replaceAll("__NAME__", name)
      .replaceAll("__FLOVATAR_PROMPT__", flovatarPrompt)
      .replaceAll("__TOKENS_PROMPT__", tokensPrompt)
  }
}

module.exports = OpenaiService;
