const console = require('console');
const express = require('express');
const fs = require('fs');
const https = require('https');

const key = fs.readFileSync('crt/itworks2020.key', 'utf8');
const crt = fs.readFileSync('crt/itworks2020.crt', 'utf8');

const app = express();
app.use(express.static('src'));

var server = https.createServer({key: key, cert: crt}, app);

const port = 443;
console.log(`listening on port ${port}`);

server.listen(port);
