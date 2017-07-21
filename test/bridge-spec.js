const should = require('should');

const elmServerless = require('../src-bridge');

const { httpApi } = elmServerless;

describe('elmServerless', () => {
  describe('.httpApi({ handler, config, requestPort, responsePort })', () => {
    it('is a function', () => {
      should(httpApi).be.a.Function();
    });
  });
});
