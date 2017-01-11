const httpApi = (handler) => (event, context, callback) => {
  const params = event.pathParameters || {};
  const stage = (event.requestContext || {}).stage || 'local';
  const req = {
    method: event.httpMethod || event.method,
    path: `/${params[0] || params['proxy'] || ''}`,
  }
  const app = handler.worker(req);

  app.ports.response.subscribe((args) => {
    const res = {
      statusCode: args[0] || 500,
      body: args[1] || '',
    };
    callback(null, res);
  });

  app.ports.endpoint.send(stage);
};

module.exports.httpApi = httpApi;
