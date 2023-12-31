const express = require('express');
const router = express.Router();
const auth = require('./auth');
const openai = require('./openai');
const contact = require('./contact');
const stripe = require('./stripe');
const flow = require('./flow');
const hook = require('./hook');
const createError = require('http-errors')

router.get('/', (req, res) => {
    res.send('Hello World!');
})

router.use('/auth', auth);
router.use('/openai', openai)
router.use('/contacts', contact)
router.use('/stripe', stripe)
router.use('/flow', flow)
router.use('/hooks', hook)

router.use( async (req, res, next) => {
    next(createError.NotFound('Route not Found'))
})

router.use( (err, req, res, next) => {
    res.status(err.status || 500).json({
        status: false,
        message: err.message
    })
})

module.exports = router;