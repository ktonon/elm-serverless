const defaults = require('superagent-defaults');
const supertest = require('supertest');

const port = 3001;
const endpoint = `http://localhost:${port}`;

module.exports = defaults(supertest(endpoint));
module.exports.port = port;
