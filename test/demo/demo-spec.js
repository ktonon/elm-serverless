const request = require('./request');

describe('The demo server', () => {
  describe('GET /', () => {
    it('expects an Authorization header', () =>
      request.get('/')
        .expect(401)
    );

    it('has status 200', () =>
      request.get('/')
        .set('Authorization', 'anything')
        .expect(200)
    );

    it('responds with plain text', () =>
      request.get('/')
        .set('Authorization', 'anything')
        .then(res => {
          res.headers.should.have.property('content-type')
            .which.equal('text/text; charset=utf-8');
          res.text.should.equal('Home');
        })
    );
  });

  describe('POST /', () => {
    it('has status 405', () =>
      request.post('/')
        .set('Authorization', 'anything')
        .expect(405)
    );
  });

  describe('GET /buggy', () => {
    it('has status 500', () =>
      request.get('/buggy')
        .set('Authorization', 'anything')
        .expect(500)
    );

    it('responds with plain text', () =>
      request.get('/buggy')
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
      request.get('/some-random-path')
        .set('Authorization', 'anything')
        .expect(404)
    );

    it('responds with plain text', () =>
      request.get('/some-random-path')
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
      request.post('/quote')
        .set('Authorization', 'anything')
        .expect(501).then(res => {
          res.text.should.match(/^Not implemented/);
        })
    );
  });

  describe('PUT /quote', () => {
    it('has status 405', () =>
      request.put('/quote')
        .set('Authorization', 'anything')
        .expect(405).then(res => {
          res.text.should.equal('Method not allowed');
        })
    );
  });
});
