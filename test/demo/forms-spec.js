const request = require('./request');

const path = (relative) => `/forms${relative}`;

describe('Demo: /forms', () => {
  it('GET has status 405', () =>
    request.get(path('/')).expect(405)
  );

  it('POST text/text has status 400', () =>
    request
      .post(path('/'))
      .set('content-type', 'text/text')
      .expect(400)
  );

  it('POST application/json invalid JSON has status 400', () =>
    request
      .post(path('/'))
      .set('content-type', 'application/json')
      .send('{,}')
      .expect(400)
  );

  it('POST application/json wrong object has status 400', () =>
    request
      .post(path('/'))
      .set('content-type', 'application/json')
      .send({ age: 4 })
      .expect(400)
  );

  it('POST application/json correct object has status 200', () =>
    request
      .post(path('/'))
      .set('content-type', 'application/json')
      .send({ age: 4, name: 'fred' })
      .expect(200)
      .then(res => {
        res.text.should.equal('{ name = "fred", age = 4 }');
      })
  );
});
