const router = require('express').Router()
const AuthController = require('../controllers/auth.controller')
const bodyParser = require('body-parser');

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

// register
router.post('/', AuthController.register)
// login
router.post('/login', AuthController.login)

module.exports = router