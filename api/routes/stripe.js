const router = require('express').Router()
const StripeController = require('../controllers/stripe.controller')
const bodyParser = require('body-parser');
const auth = require('../middlewares/auth')
const cors = require('cors')

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

router.post('/create_checkout_session', auth, cors(), StripeController.createCheckoutSession)
router.get('/payment_succeed', cors(), function (req, res) {
  res.sendFile(__dirname + '/succeed.html')
})
router.get('/payment_cancelled', cors(), function (req, res) {
  res.sendFile(__dirname + '/cancelled.html')
})

module.exports = router
