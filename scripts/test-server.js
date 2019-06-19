const fs = require('fs');
const psList = require('ps-list'); // eslint-disable-line import/no-extraneous-dependencies
const { spawn } = require('child_process');
const { port } = require('../test/demo/request');

const args = `offline --port=${port}`.split(' ');
const logFile = `${__dirname}/test-server.log`;
const logger = console;

const findServer = () => psList().then(data => {
  const argsPattern = new RegExp(args.join(' '));
  return data.filter(({ name, cmd }) =>
    name === 'node' &&
    argsPattern.test(cmd))[0];
});

const startServer = () => new Promise((resolve, reject) => {
  const out = fs.openSync(logFile, 'w+');
  const server = spawn(`${__dirname}/../node_modules/.bin/serverless`, args, {
    cwd: `${__dirname}/../demo`,
    detached: true,
    env: Object.assign({
      demo_enableAuth: 'true',
    }, process.env),
    stdio: ['ignore', out, out],
  });
  server.unref();

  let seenBytes = 0;
  const readNext = () => {
    const stat = fs.fstatSync(out);
    const newBytes = stat.size - seenBytes;
    if (newBytes > 0) {
      const data = Buffer.alloc(newBytes);
      fs.readSync(out, data, 0, newBytes, seenBytes);
      const line = data.toString('utf8');
      seenBytes = stat.size;

      if (/error/i.test(line)) {
        reject(`test server: ${line}`);
        return;
      } else if (/Serverless: Offline listening on/.test(line)) {
        resolve(server.pid);
        return;
      }
    }
    setTimeout(readNext, 200);
  };
  readNext();

  server.on('close', code => {
    reject(`test server terminated with code: ${code}`);
  });
}).then(pid => {
  logger.info(`Test server started (${pid})`);
  return true;
}).catch(err => {
  logger.error(err);
  process.exit(1);
});

findServer().then(server => {
  if (server) {
    logger.info(`Stopping old test server (${server.pid})`);
    process.kill(server.pid);
  }
  logger.info('Starting new test server');
  setTimeout(startServer, 500);
}).catch(err => {
  logger.error(err);
  process.exit(1);
});
