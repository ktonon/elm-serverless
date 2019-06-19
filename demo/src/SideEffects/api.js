const elmServerless = require('../../../src-bridge');

const { Elm } = require('./API.elm');

module.exports.handler = elmServerless.httpApi({
  handler: Elm.SideEffects.API,
});
