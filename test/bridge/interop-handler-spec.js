const should = require('should');
const sinon = require('sinon');

const interopHandler = require('../../src-bridge/interop-handler');

const id = 'id';

const makeHandler = ({ interop = {} } = {}) => {
  const config = { interop, resultPort: { send: sinon.spy() } };
  return Object.assign(interopHandler(config), config);
};

describe('interopHandler({ interop, resultPort })', () => {
  it('is a function', () => {
    should(makeHandler()).be.a.Function();
  });

  it('throws if the interop handler is missing', () => {
    (() => makeHandler()(id, 'getSomething', {})).should.throw(/^Missing interop/);
  });

  it('calls the resultPort with the value returned by the handler', () => {
    const h = makeHandler({ interop: { getSomething: n => n * n } });
    h(id, 'getSomething', 5);
    h.resultPort.send.calledWith([id, 'getSomething', 25]).should.be.true();
  });

  it('works with handlers that return promises', () => {
    const h = makeHandler({ interop: { getSomething: n => Promise.resolve(n + 1) } });
    return h(id, 'getSomething', 5).then(() => {
      h.resultPort.send.calledWith([id, 'getSomething', 6]).should.be.true();
    });
  });
});
