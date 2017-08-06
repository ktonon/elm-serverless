const fs = require('fs');
const ps = require('ps-node'); // eslint-disable-line import/no-extraneous-dependencies
const { spawn } = require('child_process');
const { port } = require('../test/demo/request');

const args = `offline --port=${port}`.split(' ');
const logFile = `${__dirname}/test-server.log`;

const findServer = () => new Promise((resolve, reject) => {
  ps.lookup({ command: 'node' }, (err, results) => {
    if (err) {
      reject(err);
      return;
    }
    const [server] = results.filter(proc => {
      const [cmd, ...rest] = proc.arguments;
      return /\bserverless$/.test(cmd) && rest.reduce((acc, arg, i) => acc && arg === args[i]);
    });
    resolve(server);
  });
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
      seenBytes = stat.size;

      if (/error/i.test(data)) {
        reject(`test server: ${data}`);
        return;
      } else if (/Version: webpack \d+\.\d+\.\d+/.test(data)) {
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
  console.log(`Test server started (${pid})`); // eslint-disable-line no-console
  return true;
}).catch(err => {
  console.error(err); // eslint-disable-line no-console
  process.exit(1);
});

findServer().then(server => {
  if (server) {
    console.log(`Stopping old test server (${server.pid})`); // eslint-disable-line no-console
    process.kill(server.pid);
  }
  startServer();
});
