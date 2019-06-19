const request = require('./request');

const path = (relative) => `/config${relative}`;

describe('Demo: /config', () => {
  it('has status 200', () =>
    request.get(path('/')).expect(200)
  );

  it('responds with the parsed config', () =>
    request.get(path('/'))
      .then(res => {
        res.text.should.equal('Config: {"auth":{"secret":"secret"},"someService":{"protocol":"http","host":"localhost","port":3131}}');
      })
  );
});
