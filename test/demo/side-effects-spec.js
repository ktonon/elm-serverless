const co = require('co');
const should = require('should');

const request = require('./request');

const path = (relative) => `/side-effects/${relative}`;

describe('Demo: /side-effects', () => {
  describe('GET /', () => {
    it('gets a random integer', () => co(function* () {
      const n = 20;
      const responses = yield [...Array(n)].map(() =>
        request.get(path('/')).expect(200));
      should(typeof responses[0].body).equal('number');
      // Seed is probably current time, if a couple of requests start
      // at the same time, they will share the same seed. To fix this,
      // we'd have to add some way of sharing state between connections.
      should(new Set(responses.map(r => r.body)).size).above(1);
    }));
  });

  describe('GET /:upper', () => {
    it('gets a random integer below :upper', () => co(function* () {
      const upper = 10;
      const n = 10;
      const responses = yield [...Array(n)].map(() =>
        request.get(path(upper)).expect(200));
      responses.forEach(({ body }) => {
        body.should.be.aboveOrEqual(0);
        body.should.be.belowOrEqual(upper);
      });
    }));
  });

  describe('GET /:lower/:upper', () => {
    it('gets a random integer between :lower and :upper', () => co(function* () {
      const n = 50;
      // This one also tests that messages get mapped to the appropriate
      // connection.
      const ranges = [...Array(n)].map((_, i) => [i * 10, ((i + 1) * 10) - 1]);
      const responses = yield ranges.map(range =>
        request.get(path(range.join('/'))).expect(200));
      ranges.forEach(([lower, upper], index) => {
        const { body } = responses[index];
        body.should.be.aboveOrEqual(lower);
        body.should.be.belowOrEqual(upper);
      });
    }));
  });

  describe('GET /unit', () => {
    it('gets a random float between 0 and 1', () => co(function* () {
      const n = 20;
      const responses = yield [...Array(n)].map(() =>
        request.get(path('unit')).expect(200));
      responses.forEach(({ body }) => {
        should(typeof body).equal('number');
        body.toString().should.match(/^[01]\.\d+$/);
        body.should.be.aboveOrEqual(0);
        body.should.be.belowOrEqual(1);
      });
      should(new Set(responses.map(r => r.body)).size).above(1);
    }));
  });
});
