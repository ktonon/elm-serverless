const request = require('./request');

const greeting = 'Hello Elm on AWS Lambda';
const path = (relative) => `${relative}`;

describe('Demo: /', () => {
  describe('GET /', () => {
    it('has status 200', () =>
      request.get(path('/')).expect(200)
    );

    it('responds with plain text', () =>
      request.get(path('/'))
        .then(res => {
          res.headers.should.have.property('content-type')
            .which.equal('text/text; charset=utf-8');
          res.text.should.equal(greeting);
        })
    );
  });
});
