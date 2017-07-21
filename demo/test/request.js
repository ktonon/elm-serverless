// eslint-disable-next-line import/no-extraneous-dependencies
const defaults = require('superagent-defaults');
// eslint-disable-next-line import/no-extraneous-dependencies
const supertest = require('supertest');

const endpoint = 'http://localhost:3001';

module.exports = defaults(supertest(endpoint));
