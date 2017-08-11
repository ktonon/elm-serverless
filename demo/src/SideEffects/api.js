const elmServerless = require('../../../src-bridge');

const { SideEffects } = require('./API.elm');

module.exports.handler = elmServerless.httpApi({
  handler: SideEffects.API,
});
