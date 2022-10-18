//mongodb
require('./config/db');

const app = require('express')();
const port = 3000;

//for accepting post from data
const bodyParser = require('express').json;
app.use(bodyParser());

app.listen(port, () => {
    console.log(`server running on port ${port}`);
})