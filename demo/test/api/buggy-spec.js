const request = require('../request');

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
  )
});
