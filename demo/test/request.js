const defaults = require('superagent-defaults');
const supertest = require('supertest-as-promised');

const endpoint = 'http://localhost:3000';

module.exports = defaults(supertest(endpoint));
