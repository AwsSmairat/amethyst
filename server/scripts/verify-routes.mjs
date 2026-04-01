#!/usr/bin/env node
/**
 * Smoke-test public routes. Requires the API to be running (default http://localhost:4000).
 * Usage: BASE_URL=http://127.0.0.1:4000 npm run verify:routes
 */

const base = (process.env.BASE_URL || 'http://localhost:4000').replace(/\/$/, '');

async function fetchJson(path) {
  const url = `${base}${path.startsWith('/') ? path : `/${path}`}`;
  const res = await fetch(url, { headers: { Accept: 'application/json' } });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = text;
  }
  return { status: res.status, json, url };
}

function ok(cond, name, detail = '') {
  const pass = Boolean(cond);
  console.log(pass ? '✓' : '✗', name, detail);
  return pass;
}

async function main() {
  let failed = 0;

  const checks = [
    ['Root', '/', (d) => d.json?.message],
    ['Health (root)', '/health', (d) => d.json?.success === true],
    ['API health', '/api/health', (d) => d.json?.success === true && d.json?.message === 'API is healthy'],
    ['OpenAPI JSON', '/api/openapi.json', (d) => d.json?.openapi === '3.0.3'],
  ];

  for (const [name, path, predicate] of checks) {
    try {
      const d = await fetchJson(path);
      const pass = d.status >= 200 && d.status < 400 && predicate(d);
      if (!ok(pass, `${name} (${path})`, pass ? `HTTP ${d.status}` : `HTTP ${d.status}`)) {
        failed++;
      }
    } catch (e) {
      ok(false, `${name} (${path})`, String(e.message || e));
      failed++;
    }
  }

  try {
    const docs = await fetch(`${base}/api/docs`);
    ok(
      docs.ok && docs.headers.get('content-type')?.includes('text/html'),
      'Swagger UI (/api/docs)',
      `HTTP ${docs.status}`
    );
    if (!docs.ok) failed++;
  } catch (e) {
    ok(false, 'Swagger UI (/api/docs)', String(e.message || e));
    failed++;
  }

  if (failed) {
    console.error(`\n${failed} check(s) failed. Is the server running at ${base}?`);
    process.exit(1);
  }
  console.log('\nAll public checks passed.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
