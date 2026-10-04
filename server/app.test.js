const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const { createApp } = require('./app');

async function start(dataDir, maxUploadBytes = 1024) {
  const { app, db } = createApp({ dataDir, maxUploadBytes });
  const server = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)); });
  return { base: `http://127.0.0.1:${server.address().port}`, db,
    close: () => new Promise(resolve => server.close(() => { db.close(); resolve(); })) };
}
async function upload(base, folder, { id = randomUUID(), content = 'hello local files', name = 'note.txt', category, caption = 'Test caption' } = {}) {
  const body = new FormData();
  body.set('uploadId', id); body.set('name', name); body.set('caption', caption);
  if (category) body.set('category', category);
  body.set('file', new Blob([content], { type: 'text/plain' }), name);
  return fetch(`${base}/folders/${folder}/files`, { method: 'POST', body });
}

test('unauthenticated folder/upload/list/download/retry/delete workflow survives restart', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'filenest-test-'));
  let server = await start(dir);
  try {
    assert.equal((await (await fetch(`${server.base}/health`)).json()).storage, 'sqlite');
    const created = await fetch(`${server.base}/folders`, { method: 'POST' });
    assert.equal(created.status, 201);
    const folder = await created.json();
    const joined = await (await fetch(`${server.base}/folders/code/${folder.code.toLowerCase()}`)).json();
    assert.equal(joined.folderId, folder.folderId);
    const id = randomUUID();
    const response = await upload(server.base, folder.folderId, { id });
    assert.equal(response.status, 201);
    const file = await response.json();
    assert.equal(file.category, 'documents');
    assert.equal(file.caption, 'Test caption');
    assert.equal(file.size, 17);
    assert.equal(fs.readFileSync(path.join(dir, file.path), 'utf8'), 'hello local files');
    assert.equal(server.db.prepare('SELECT path FROM files WHERE id = ?').get(id).path, file.path);
    assert.equal((await upload(server.base, folder.folderId, { id })).status, 200);
    assert.equal((await upload(server.base, folder.folderId, { id, content: 'different' })).status, 409);
    assert.equal((await (await fetch(`${server.base}/folders/${folder.folderId}/files`)).json()).files.length, 1);
    await server.close(); server = await start(dir);
    assert.equal((await (await fetch(`${server.base}/folders/code/${folder.code}`)).json()).folderId, folder.folderId);
    const download = await fetch(`${server.base}${file.downloadPath}`);
    assert.equal(download.status, 200);
    assert.match(download.headers.get('content-disposition'), /attachment/);
    assert.equal(await download.text(), 'hello local files');
    const other = await (await fetch(`${server.base}/folders`, { method: 'POST' })).json();
    assert.equal((await upload(server.base, other.folderId, { id })).status, 409);
    assert.equal((await fetch(`${server.base}/folders/${other.folderId}/files/${id}`, { method: 'DELETE' })).status, 404);
    assert.equal((await fetch(`${server.base}/folders/${folder.folderId}/files/${id}`, { method: 'DELETE' })).status, 204);
    assert.equal((await fetch(`${server.base}${file.downloadPath}`)).status, 404);
    assert.equal((await upload(server.base, folder.folderId, { id })).status, 409);
    assert.deepEqual(fs.readdirSync(path.join(dir, 'incoming')), []);
  } finally { await server.close(); fs.rmSync(dir, { recursive: true, force: true }); }
});

test('validates uploads, confines paths, handles concurrent retries and cleans temporary files', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'filenest-test-'));
  const server = await start(dir);
  try {
    const folder = await (await fetch(`${server.base}/folders`, { method: 'POST' })).json();
    assert.equal((await fetch(`${server.base}/folders/${folder.folderId}/files`, { method: 'POST' })).status, 400);
    assert.equal((await upload(server.base, 'missing')).status, 404);
    assert.equal((await upload(server.base, folder.folderId, { id: '../../escape' })).status, 400);
    assert.equal((await upload(server.base, folder.folderId, { category: '../../escape' })).status, 400);
    assert.equal((await upload(server.base, folder.folderId, { content: 'a'.repeat(2048) })).status, 413);
    const id = randomUUID();
    const responses = await Promise.all([upload(server.base, folder.folderId, { id, name: '../../safe.txt' }), upload(server.base, folder.folderId, { id, name: '../../safe.txt' })]);
    assert.deepEqual(responses.map(r => r.status).sort(), [200, 201]);
    const file = await responses[0].json();
    assert.equal(file.name, 'safe.txt');
    assert.ok(path.resolve(dir, file.path).startsWith(dir + path.sep));
    const zero = await upload(server.base, folder.folderId, { content: '' });
    assert.equal(zero.status, 201);
    assert.equal((await zero.json()).size, 0);
    assert.deepEqual(fs.readdirSync(path.join(dir, 'incoming')), []);
  } finally { await server.close(); fs.rmSync(dir, { recursive: true, force: true }); }
});
