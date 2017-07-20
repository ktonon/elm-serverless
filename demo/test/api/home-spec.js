const request = require('../request');

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
  )
});
