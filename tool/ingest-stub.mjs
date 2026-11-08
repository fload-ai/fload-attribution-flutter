#!/usr/bin/env node
// A local stand-in for Fload's ingest (POST /attribution/v1/installs and
// /attribution/v1/identify), for running the example apps. It checks each
// request against the wire contract, answers 202 (or 400 with the reasons),
// and keeps what it received at GET /__requests. It never forwards anything.
//
//   node tool/ingest-stub.mjs [--port 3999] [--log requests.jsonl] [--expect-wrapper flutter]
//
// Each recorded request says which wrapper sent it (`wrapper`: the request's
// sdk.wrapper, or null). The server drops a wrapper it does not know rather
// than refusing the install, and so does the stub, unless --expect-wrapper
// is given: then a request without a valid sdk.wrapper of that name is a 400.
//
// The iOS Simulator reaches it at http://localhost:3999, the Android
// emulator at http://10.0.2.2:3999.
import { createServer } from 'node:http';
import { appendFileSync } from 'node:fs';

const args = process.argv.slice(2);
const option = (name, fallback) => {
  const at = args.indexOf(name);
  return at >= 0 && args[at + 1] ? args[at + 1] : fallback;
};
const port = Number(option('--port', process.env.PORT ?? 3999));
const logFile = option('--log', null);
const expectWrapper = option('--expect-wrapper', null);
// The server's limits: 8 KB for an install, 2 KB for an identify.
const maxBody = { '/attribution/v1/installs': 8 * 1024, '/attribution/v1/identify': 2 * 1024 };
const received = [];

// Mirrors packages/shared-types/src/contracts/attribution-ingest.ts in Fload.
const isString = (value, max) => typeof value === 'string' && value.trim().length > 0 && value.length <= max;
const isPhoneId = (value) => typeof value === 'string' && /^[A-Za-z0-9._:-]{8,128}$/.test(value);
const isOptionalString = (value, max) => value === undefined || isString(value, max);
const isTimestamp = (value) => typeof value === 'string' && !Number.isNaN(Date.parse(value)) && /T.*Z$/.test(value);
const isOptionalTimestamp = (value) => value === undefined || isTimestamp(value);
// The server's wrapper names (ATTRIBUTION_SDK_WRAPPERS) and its semver check.
const wrapperNames = ['flutter', 'react-native', 'capacitor', 'cordova', 'unity', 'dotnet', 'kmp'];
const isSemver = (value) => typeof value === 'string' && value.length <= 64 && /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.+-]+)?$/.test(value);

/** The request's sdk.wrapper as the server reads it, or null when it would drop it. */
function readWrapper(sdk) {
  const wrapper = sdk?.wrapper;
  if (!wrapper || !wrapperNames.includes(wrapper.name) || !isSemver(wrapper.version)) return null;
  return { name: wrapper.name, version: wrapper.version };
}

function checkWrapper(body, problems) {
  if (!expectWrapper) return;
  const wrapper = readWrapper(body.sdk);
  if (wrapper?.name !== expectWrapper) problems.push(`sdk.wrapper (expected a valid "${expectWrapper}" wrapper)`);
}

function checkCommon(body, problems) {
  if (!isPhoneId(body.requestId)) problems.push('requestId');
  if (!isPhoneId(body.installReference)) problems.push('installReference');
  if (body.platform !== 'ios' && body.platform !== 'android') problems.push('platform');
  if (!isOptionalString(body.appUserId, 256)) problems.push('appUserId');
}

function checkAppleAds(appleAds, problems) {
  const statuses = ['token', 'token_expired', 'unsupported_os', 'token_error'];
  if (!appleAds || !statuses.includes(appleAds.status)) return problems.push('appleAds.status');
  const hasToken = typeof appleAds.token === 'string' && appleAds.token.length > 0;
  if ((appleAds.status === 'token') !== hasToken) problems.push('appleAds.token is sent exactly when status is "token"');
  if (hasToken && !/^[A-Za-z0-9+/=_-]{1,4096}$/.test(appleAds.token)) problems.push('appleAds.token');
  if (!isOptionalTimestamp(appleAds.tokenCreatedAt)) problems.push('appleAds.tokenCreatedAt');
}

function checkPlayReferrer(play, problems) {
  const statuses = ['ok', 'unavailable', 'not_supported', 'error'];
  if (!play || !statuses.includes(play.status)) return problems.push('playReferrer.status');
  if (!isOptionalString(play.referrer, 1024)) problems.push('playReferrer.referrer');
  for (const field of ['referrerClickAt', 'installBeginAt', 'referrerClickServerAt', 'installBeginServerAt']) {
    if (!isOptionalTimestamp(play[field])) problems.push(`playReferrer.${field}`);
  }
  if (!isOptionalString(play.installVersion, 64)) problems.push('playReferrer.installVersion');
  if (play.googlePlayInstant !== undefined && typeof play.googlePlayInstant !== 'boolean') {
    problems.push('playReferrer.googlePlayInstant');
  }
}

function checkInstall(body) {
  const problems = [];
  checkCommon(body, problems);
  if (!isString(body.appId, 256)) problems.push('appId');
  for (const field of ['appVersion', 'appBuild', 'osVersion', 'deviceModel', 'locale']) {
    if (!isOptionalString(body[field], 64)) problems.push(field);
  }
  if (!body.sdk || !isString(body.sdk.name, 64) || !isString(body.sdk.version, 64)) problems.push('sdk');
  checkWrapper(body, problems);
  if (!isTimestamp(body.firstLaunchAt)) problems.push('firstLaunchAt');
  if (body.platform === 'ios') {
    checkAppleAds(body.appleAds, problems);
    if (body.playReferrer !== undefined) problems.push('iOS sends appleAds only');
  }
  if (body.platform === 'android') {
    checkPlayReferrer(body.playReferrer, problems);
    if (body.appleAds !== undefined) problems.push('Android sends playReferrer only');
  }
  return problems;
}

function checkIdentify(body) {
  const problems = [];
  checkCommon(body, problems);
  if (!isString(body.appUserId, 256)) problems.push('appUserId (required)');
  checkWrapper(body, problems);
  return problems;
}

const routes = {
  '/attribution/v1/installs': checkInstall,
  '/attribution/v1/identify': checkIdentify,
};

function answer(response, status, payload) {
  response.writeHead(status, { 'Content-Type': 'application/json' });
  response.end(JSON.stringify(payload));
}

function record(entry) {
  received.push(entry);
  const line = JSON.stringify(entry);
  console.log(line);
  if (logFile) appendFileSync(logFile, `${line}\n`);
}

function handlePost(request, response, raw) {
  const check = routes[request.url];
  if (!check) return answer(response, 404, { error: 'not found' });
  const key = request.headers['x-fload-write-key'];
  if (typeof key !== 'string' || !key.startsWith('fload_pk_')) return answer(response, 401, { error: 'unknown key' });
  if (raw.length > maxBody[request.url]) return answer(response, 413, { error: 'too large' });
  let body;
  try {
    body = JSON.parse(raw.toString('utf8'));
  } catch {
    return answer(response, 400, { error: 'not json' });
  }
  const problems = check(body);
  const wrapper = readWrapper(body.sdk);
  record({ at: new Date().toISOString(), path: request.url, userAgent: request.headers['user-agent'], bytes: raw.length, valid: problems.length === 0, problems, wrapper, body });
  if (problems.length > 0) return answer(response, 400, { error: 'invalid', problems });
  return answer(response, 202, { accepted: true });
}

const server = createServer((request, response) => {
  if (request.method === 'GET' && request.url === '/__requests') return answer(response, 200, received);
  if (request.method === 'DELETE' && request.url === '/__requests') {
    received.length = 0;
    return answer(response, 200, { cleared: true });
  }
  if (request.method !== 'POST') return answer(response, 405, { error: 'method' });
  const chunks = [];
  request.on('data', (chunk) => chunks.push(chunk));
  request.on('end', () => handlePost(request, response, Buffer.concat(chunks)));
});

server.listen(port, '127.0.0.1', () => {
  console.error(`Fload ingest stub on http://127.0.0.1:${port} (Android emulator: http://10.0.2.2:${port})`);
});
