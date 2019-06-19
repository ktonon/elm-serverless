const should = require('should');
const sinon = require('sinon');

const { httpApi } = require('../../src-bridge');
const spyLogger = require('./spy-logger');

const requestPort = 'requestPort';
const responsePort = 'responsePort';
const makeHandler = () => ({
  init: sinon.stub().returns({
    ports: {
      requestPort: { send: sinon.spy() },
      responsePort: { subscribe: sinon.spy() },
    },
  })
});

describe('elmServerless', () => {
  describe('.httpApi({ handler, config, requestPort, responsePort })', () => {
    it('is a function', () => {
      should(httpApi).be.a.Function();
    });

    it('works with valid handler, requestPort, and responsePort', () => {
      (() => httpApi({ handler: makeHandler(), requestPort, responsePort }))
        .should.not.throw();
    });

    it('passes config to the handler.init function', () => {
      const h = makeHandler();
      const config = { some: { app: ['specific', 'configuration'] } };
      httpApi({ handler: h, config, requestPort, responsePort });
      h.init.calledWith({ flags: config }).should.be.true();
    });

    it('subscribes to the responsePort', () => {
      const h = makeHandler();
      httpApi({ handler: h, requestPort, responsePort });
      const subscribe = h.init().ports.responsePort.subscribe;
      subscribe.called.should.be.true();
      const call = subscribe.getCall(0);
      const [func] = call.args;
      should(func).be.a.Function();
    });

    it('handles responses', () => {
      const h = makeHandler();
      const logger = spyLogger();
      httpApi({ handler: h, logger, requestPort, responsePort });
      const subscribe = h.init().ports.responsePort.subscribe;
      const responseHandler = subscribe.getCalls()[0].args[0];
      logger.error.getCalls().should.be.empty();
      responseHandler(['id', '__response__', {}]);
      logger.error.getCalls().should.not.be.empty();
      logger.error.getCalls()[0].args.should.deepEqual(['No callback for ID: id']);
    });

    it('handles interop', () => {
      const h = makeHandler();
      const logger = spyLogger();
      httpApi({ handler: h, logger, requestPort, responsePort });
      const subscribe = h.init().ports.responsePort.subscribe;
      const responseHandler = subscribe.getCalls()[0].args[0];
      (() => responseHandler(['id', 'missingHandler', {}])).should.throw(/^Missing interop/);
    });

    it('returns a request handler', () => {
      const h = makeHandler();
      const func = httpApi({ handler: h, requestPort, responsePort });
      should(func).be.a.Function();
      should(func.name).equal('requestHandler');
    });

    it('requires a handler', () => {
      (() => httpApi({ requestPort, responsePort }))
        .should.throw(/^Missing handler argument/);
    });

    it('requires a valid handler', () => {
      (() => httpApi({ handler: { init: 'foo' }, requestPort, responsePort }))
        .should.throw(/^Invalid handler argument(.|\n)*?Got: { init: 'foo' }/);
    });

    it('expects handler.init to return an object', () => {
      (() => httpApi({
        handler: { init: sinon.stub().returns('foo') },
        requestPort,
        responsePort,
      }))
        .should.throw(/^handler\.init did not return valid Elm app.*?Got: 'foo'$/);
    });

    it('requires a requestPort', () => {
      (() => httpApi({
        handler: makeHandler(),
        requestPort: 'reqPort',
        responsePort,
      }))
        .should.throw(/^No request port named reqPort among: \[requestPort, responsePort\]$/);
    });

    it('requires a valid requestPort', () => {
      (() => httpApi({
        handler: makeHandler(),
        requestPort: 'responsePort',
        responsePort,
      }))
        .should.throw(/^Invalid request port/);
    });

    it('requires a responsePort', () => {
      (() => httpApi({
        handler: makeHandler(),
        requestPort,
        responsePort: 'respPort',
      }))
        .should.throw(/^No response port named respPort among: \[requestPort, responsePort\]$/);
    });

    it('requires a valid responsePort', () => {
      (() => httpApi({
        handler: makeHandler(),
        requestPort,
        responsePort: 'requestPort',
      }))
        .should.throw(/^Invalid response port/);
    });
  });
});
