const should = require('should');

const request = require('./request');

const path = (relative) => `/pipelines${relative}`;

describe('Demo: /pipelines', () => {
  it('has status 401', () =>
    request.get(path('/')).expect(401)
  );

  it('terminates the pipeline early if Unauthorized', () =>
    request.get(path('/')).expect(401).then(res => {
      should(res.headers).have.property('x-from-first-plug').equal('foo');
      should(res.headers).not.have.property('x-from-last-plug');
      res.text.should.startWith('Unauthorized');
    })
  );

  it('completes the pipeline if Authorized', () =>
    request
      .get(path('/'))
      .set('Authorization', 'anything')
      .expect(200)
      .then(res => {
        should(res.headers).have.property('x-from-first-plug').equal('foo');
        should(res.headers).have.property('x-from-last-plug').equal('bar');
        res.text.should.equal('Pipeline applied');
      })
  );
});
