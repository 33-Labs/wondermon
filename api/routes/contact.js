const router = require('express').Router()
const ContactController = require('../controllers/contact.controller')
const bodyParser = require('body-parser');
const auth = require('../middlewares/auth')

router.use(bodyParser.urlencoded({ extended: true }))
router.use(bodyParser.json())

router.post('/', auth, ContactController.create)
router.delete('/:id', auth, ContactController.delete)
router.get('/', auth, ContactController.all)

module.exports = router
