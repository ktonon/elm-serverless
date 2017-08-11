const request = require('./request');

const path = (relative) => `/routing${relative}`;

describe('Demo: /routing', () => {
  it('GET / routes to the home page', () =>
    request.get(path('/')).expect(200).then(res => {
      res.text.should.equal('The home page');
    })
  );

  it('GET /blog routes to the blog list', () =>
    request.get(path('/blog')).expect(200).then(res => {
      res.text.should.equal('List of recent posts...');
    })
  );

  it('GET /blog/some-slug routes to a specific post', () =>
    request.get(path('/blog/some-slug')).expect(200).then(res => {
      res.text.should.equal('Specific post: some-slug');
    })
  );

  it('POST /blog returns 405', () =>
    request.post(path('/blog')).expect(405)
  );

  it('GET /some/undefined/path returns 404', () =>
    request.post(path('/some/undefined/path')).expect(404)
  );
});
