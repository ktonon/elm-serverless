const sinon = require('sinon');

const spyLogger = () => ({
  info: sinon.spy(),
  warn: sinon.spy(),
  error: sinon.spy(),
  trace: sinon.spy(),
});

module.exports = spyLogger;
