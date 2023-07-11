const router = require('express').Router()
const FlowController = require('../controllers/flow.controller')
const bodyParser = require('body-parser');
const auth = require('../middlewares/auth')

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

// send_token
router.post('/send_token', auth, FlowController.sendToken)

module.exports = router
