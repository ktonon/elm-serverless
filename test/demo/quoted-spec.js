const co = require('co');
const should = require('should');

const request = require('./request');

const path = (relative) => `/quoted${relative}`;

describe('Demo: /quoted', () => {
  describe('GET /', () => {
    it('expects an Authorization header', () =>
      request.get(path('/'))
        .expect(401)
    );

    it('has status 200', () =>
      request.get(path('/'))
        .set('Authorization', 'anything')
        .expect(200)
    );

    it('responds with plain text', () =>
      request.get(path('/'))
        .set('Authorization', 'anything')
        .then(res => {
          res.headers.should.have.property('content-type')
            .which.equal('text/text; charset=utf-8');
          res.text.should.startWith('Home');
        })
    );

    it('parses a single query parameter', () =>
      request.get(path('/?q=foo%20bar'))
        .set('Authorization', 'anything')
        .expect(200).then(res => {
          res.text.should.match(/"q":"foo bar"/);
        })
    );

    it('parses a two query parameters', () =>
      request.get(path('/?q=*&sort=asc'))
        .set('Authorization', 'anything')
        .expect(200).then(res => {
          res.text.should.match(/"q":"*"/);
          res.text.should.match(/"sort":"Asc"/);
        })
    );

    it('provides default query values', () =>
      request.get(path('/'))
        .set('Authorization', 'anything')
        .expect(200).then(res => {
          res.text.should.match(/"q":""/);
          res.text.should.match(/"sort":"Desc"/);
        })
    );
  });

  describe('POST /', () => {
    it('has status 405', () =>
      request.post(path('/'))
        .set('Authorization', 'anything')
        .expect(405)
    );
  });

  describe('GET /buggy', () => {
    it('has status 500', () =>
      request.get(path('/buggy'))
        .set('Authorization', 'anything')
        .expect(500)
    );

    it('responds with plain text', () =>
      request.get(path('/buggy'))
        .set('Authorization', 'anything')
        .then(res => {
          res.headers.should.have.property('content-type')
            .which.equal('text/text; charset=utf-8');
          res.text.should.equal('bugs, bugs, bugs');
        })
    );
  });

  describe('GET /some-path-that-does-not-exist', () => {
    it('has status 404', () =>
      request.get(path('/some-random-path'))
        .set('Authorization', 'anything')
        .expect(404)
    );

    it('responds with plain text', () =>
      request.get(path('/some-random-path'))
        .set('Authorization', 'anything')
        .then(res => {
          res.headers.should.have.property('content-type')
            .which.equal('text/text; charset=utf-8');
          res.text.should.startWith('Could not parse route: ');
        })
    );
  });

  describe('POST /quote', () => {
    it('has status 501', () =>
      request.post(path('/quote'))
        .set('Authorization', 'anything')
        .expect(501).then(res => {
          res.text.should.match(/^Not implemented/);
        })
    );
  });

  describe('PUT /quote', () => {
    it('has status 405', () =>
      request.put(path('/quote'))
        .set('Authorization', 'anything')
        .expect(405).then(res => {
          res.text.should.equal('Method not allowed');
        })
    );
  });

  describe('GET /number', () => {
    it('has status 200', () =>
      request.get(path('/number'))
        .set('Authorization', 'anything')
        .expect(200)
    );

    it('returns a different value each time', () => co(function* () {
      const res0 = yield request.get(path('/number')).set('Authorization', 'anything').expect(200);
      const res1 = yield request.get(path('/number')).set('Authorization', 'anything').expect(200);
      should(typeof res0.body).equal('number');
      res0.body.should.not.equal(res1.body);
    }));
  });
});
