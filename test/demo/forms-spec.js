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
      .then(res => {
        res.text.should.equal('Could not decode request body. Problem with the given value:\n\nnull\n\nExpecting an OBJECT with a field named `age`');
      })
  );

  it('POST application/json invalid JSON has status 400', () =>
    request
      .post(path('/'))
      .set('content-type', 'application/json')
      .send('{,}')
      .expect(400)
      .then(res => {
        res.text.should.equal('Could not decode request body. Problem with the given value:\n\n"{,}"\n\nThis is not valid JSON! Unexpected token , in JSON at position 1');
      })
  );

  it('POST application/json wrong object has status 400', () =>
    request
      .post(path('/'))
      .set('content-type', 'application/json')
      .send({ age: 4 })
      .expect(400)
      .then(res => {
        res.text.should.equal('Could not decode request body. Problem with the given value:\n\n{\n        "age": 4\n    }\n\nExpecting an OBJECT with a field named `name`');
      })
  );

  it('POST application/json correct object has status 200', () =>
    request
      .post(path('/'))
      .set('content-type', 'application/json')
      .send({ age: 4, name: 'fred' })
      .expect(200)
      .then(res => {
        res.text.should.equal('{"name":"fred","age":4}');
      })
  );

  it('POST text/text with JSON body has status 200', () =>
    request
      .post(path('/'))
      .set('content-type', 'text/text')
      .send('{"age":3,"name":"barney"}')
      .expect(200)
      .then(res => {
        res.text.should.equal('{"name":"barney","age":3}');
      })
  );
});
