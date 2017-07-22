const request = require('./request');

describe('The demo server', () => {
  describe('GET /', () => {
    it('has status 200', () =>
      request.get('/').expect(200)
    );

    it('responds with plain text', () =>
      request.get('/').then(res => {
        res.headers.should.have.property('content-type')
          .which.equal('text/text; charset=utf-8');
        res.text.should.equal('Home');
      })
    );
  });

  describe('GET /buggy', () => {
    it('has status 500', () =>
      request.get('/buggy').expect(500)
    );

    it('responds with plain text', () =>
      request.get('/buggy').then(res => {
        res.headers.should.have.property('content-type')
          .which.equal('text/text; charset=utf-8');
        res.text.should.equal('bugs, bugs, bugs');
      })
    );
  });

  describe('GET /some-path-that-does-not-exist', () => {
    it('has status 404', () =>
      request.get('/some-random-path').expect(404)
    );

    it('responds with plain text', () =>
      request.get('/some-random-path').then(res => {
        res.headers.should.have.property('content-type')
          .which.equal('text/text; charset=utf-8');
        res.text.should.startWith('Nothing at:');
      })
    );
  });
});
