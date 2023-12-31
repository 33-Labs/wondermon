const express = require('express');
require('@prisma/client');
const app = express();
require('dotenv').config();
const route = require('./routes');
const flow = require('./services/flow.service')
const openai = require('./services/openai.service')

const morgan = require("morgan");
const FlowService = require('./services/flow.service');

app.use(express.static('public'));
app.use(morgan('dev'));

// redirect to routes/index.js
app.use('/', route)

// start workers
// setInterval(async function() {
//   try {
//       await flow.generateWondermonAccounts()
//   } catch (e) {
//       console.log(e)
//   }
// }, 6000);

setInterval(async function() {
    try {
        await flow.generateFlowAccounts()
    } catch (e) {
        console.log(e)
    }
}, 6000);

const port = process.env.PORT || 5000;
app.listen(port, () => {
    console.log(`server is running on port ${port}`);
});