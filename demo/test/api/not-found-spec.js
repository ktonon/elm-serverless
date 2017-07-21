const request = require('../request');

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
