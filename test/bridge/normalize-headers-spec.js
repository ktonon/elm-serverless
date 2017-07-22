const norm = require('../../src-bridge/normalize-headers');

describe('norm', () => {
  it('is a function', () => {
    norm.should.be.a.Function();
  });

  it('converts header keys to lowercase', () => {
    norm({ 'Foo-Bar': 'Some Text', Age: '3' })
      .should.deepEqual({
        'foo-bar': 'Some Text',
        age: '3',
      });
  });

  it('converts numbers and bools to strings', () => {
    norm({ age: 3, good: true, bad: false })
      .should.deepEqual({
        age: '3',
        good: 'true',
        bad: 'false',
      });
  });

  it('removes keys with undefined or null values', () => {
    norm({ 'is-undef': undefined, 'is-null': null })
      .should.deepEqual({});
  });
});
