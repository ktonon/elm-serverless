const elmServerless = require('../../../src-bridge');

const elm = require('./API.elm');

module.exports.handler = elmServerless.httpApi({
  handler: elm.Forms.API,
});
