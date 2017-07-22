const validate = require('../../src-bridge/validate');

const missing = 'is missing';
const invalid = 'is invalid';
const msg = { missing, invalid };

describe('validate(obj, attr, { missing, invalid })', () => {
  it('does nothing of the validation passes', () => {
    (() => validate({ foo: () => null }, 'foo', msg))
      .should.not.throw();
  });

  it('throws if obj has not attribute named attr', () => {
    (() => validate({}, 'foo', msg))
      .should.throw('is invalid: {}');
  });

  it('throws if obj.attr is not a function', () => {
    (() => validate({ foo: 'bar' }, 'foo', msg))
      .should.throw("is invalid: { foo: 'bar' }");
  });

  it('throws if obj is undefined', () => {
    (() => validate(undefined, 'foo', msg))
      .should.throw('is missing');
  });
});
