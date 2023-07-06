const router = require('express').Router()
const OpenaiController = require('../controllers/openai.controller')
const bodyParser = require('body-parser');
const auth = require('../middlewares/auth')

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

// chat 
router.post('/chat', auth, OpenaiController.chat)

module.exports = router
