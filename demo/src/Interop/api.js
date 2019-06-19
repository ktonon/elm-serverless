const elmServerless = require('../../../src-bridge');

const { Elm } = require('./API.elm');

module.exports.handler = elmServerless.httpApi({
  handler: Elm.Interop.API,

  // One handler per Interop type constructor
  interop: {

    // Handles `GetRandomInt Int Int`
    getRandomInt: ({ lower, upper }) =>
      Math.floor(Math.random() * (upper - lower)) + lower,

    // Handles `GetRandomUnit`
    getRandomUnit: () =>
      Math.random(),
  }
});
