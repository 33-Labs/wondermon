const router = require('express').Router()
const user = require('../controllers/auth.controller')
const bodyParser = require('body-parser');

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

// register
router.post('/', user.register)

// login
router.post('/login', user.login)

module.exports = router