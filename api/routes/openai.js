const router = require('express').Router()
const OpenaiController = require('../controllers/openai.controller')
const bodyParser = require('body-parser');

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

// chat 
router.post('/chat', OpenaiController.chat)

module.exports = router
