#!/usr/bin/env node
/**
 * Proxy CORS solo para desarrollo: reenvía a IGDB v4, OAuth token de Twitch y Helix.
 *
 * Uso:
 *   node scripts/dev_api_proxy.mjs
 *
 * Flutter Web (mismas credenciales que en móvil):
 *   flutter run -d chrome --dart-define-from-file=dart_defines.local.json \
 *     --dart-define=DEV_API_PROXY=http://127.0.0.1:8787
 *
 * No usar en producción (no autentica clientes; es un túnel local).
 */
import http from 'http';
import https from 'https';
import { URL } from 'url';

const PORT = parseInt(process.env.PORT || '8787', 10);

const routes = [
  { prefix: '/v4', target: 'https://api.igdb.com' },
  { prefix: '/oauth2/', target: 'https://id.twitch.tv' },
  { prefix: '/helix/', target: 'https://api.twitch.tv' },
];

function pickTarget(pathname) {
  for (const r of routes) {
    if (pathname.startsWith(r.prefix)) return r;
  }
  return null;
}

function forward(req, res, targetOrigin) {
  const incoming = new URL(req.url, 'http://127.0.0.1');
  const dest = new URL(incoming.pathname + incoming.search, targetOrigin);
  const isHttps = dest.protocol === 'https:';
  const lib = isHttps ? https : http;
  const defaultPort = isHttps ? 443 : 80;
  const port = dest.port ? Number(dest.port, 10) : defaultPort;

  const headers = { ...req.headers };
  headers.host = dest.host;
  delete headers.connection;
  delete headers['content-length'];

  const opts = {
    hostname: dest.hostname,
    port,
    path: dest.pathname + dest.search,
    method: req.method,
    headers,
  };

  const preq = lib.request(opts, (pres) => {
    const out = { ...pres.headers };
    out['access-control-allow-origin'] = '*';
    res.writeHead(pres.statusCode || 502, out);
    pres.pipe(res);
  });
  preq.on('error', (e) => {
    res.writeHead(502, { 'content-type': 'text/plain', 'access-control-allow-origin': '*' });
    res.end(`dev_api_proxy: ${e}`);
  });
  req.pipe(preq);
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, POST, OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Client-ID, Authorization, Content-Type, Accept, X-Requested-With',
  );
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  const path = new URL(req.url, 'http://127.0.0.1').pathname;
  const route = pickTarget(path);
  if (!route) {
    res.writeHead(404, { 'content-type': 'text/plain' });
    res.end(
      'dev_api_proxy: rutas /v4/*, /oauth2/*, /helix/* — ver scripts/dev_api_proxy.mjs',
    );
    return;
  }
  forward(req, res, route.target);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`dev_api_proxy escuchando en http://127.0.0.1:${PORT}`);
});
