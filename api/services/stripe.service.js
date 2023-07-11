const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()
const createError = require('http-errors');
const flow = require('./flow.service');
const stripe = require('stripe')(process.env.STRIPE_SK)

class StripeService {
  static async createCheckoutSession(userData, itemType, tokenId) {
    const { email } = userData
    const user = await prisma.user.findUnique({
      where: { email },
      include: { flowAccount: true }
    })

    if (!user) {
      throw createError.NotFound('User not found')
    }

    if (!user.flowAccount) {
      throw createError.NotFound('flow account not found')
    }

    const _order = await prisma.stripeOrder.findFirst({
      where: { itemType: itemType, tokenId: tokenId, checkoutExpired: false } 
    })

    if (_order && !_order.checkoutCompleted) {
      throw createError.UnprocessableEntity("has been ordered")
    }

    const session = await this.doCreateSession()
    const data = {
      sessionId: session.id,
      itemType: itemType,
      tokenId: tokenId,
      recipient: user.flowAccount.address
    }
    const order = await prisma.stripeOrder.create({
      data
    })

    return {sessionID: session.id, sessionURL: session.url}
  }

  static async handleCheckoutCompleted(sessionId) {
    const order = await prisma.stripeOrder.findUnique({
      where: { sessionId }
    })

    if (order && !order.checkoutCompleted) {
      await prisma.stripeOrder.update({
        where: { sessionId },
        data: { checkoutCompleted: true }
      })
      // TODO: 
      // let itemType = "flobit"
      console.log("Handle checkout completed")
      // await flow.sendItem(order.recipient, order.tokenId, itemType)
    }
  }

  static async handleCheckoutExpired(sessionId) {
    const order = await prisma.stripeOrder.findUnique({
      where: { sessionId }
    })

    if (order) {
      await prisma.stripeOrder.update({
        where: { sessionId },
        data: { checkoutExpired: true }
      })
    }
  }

  static async doCreateSession() {
    const session = await stripe.checkout.sessions.create({
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'Flobit',
            },
            unit_amount: 1000,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${process.env.HOST}/stripe/payment_succeed`,
      cancel_url: `${process.env.HOST}/stripe/payment_cancelled`,
    })
    return session
  }
}

module.exports = StripeService