const fs = require('node:fs');
const path = require('node:path');
const { randomUUID, randomInt, createHash } = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');
const express = require('express');
const cors = require('cors');
const multer = require('multer');

function categoryFor(name, mime) {
  for (const [prefix, category] of [['image/', 'images'], ['video/', 'videos'], ['audio/', 'audio']]) {
    if (mime.startsWith(prefix)) return category;
  }
  return mime.startsWith('text/') || /\.(pdf|docx?|xlsx?|pptx?|txt|csv)$/i.test(name) ? 'documents' : 'other';
}

function createApp({ dataDir = process.env.DATA_DIR || path.join(__dirname, 'data'), maxUploadBytes = Number(process.env.MAX_UPLOAD_BYTES || 104857600) } = {}) {
  dataDir = path.resolve(dataDir);
  const tempDir = path.join(dataDir, 'incoming');
  fs.mkdirSync(tempDir, { recursive: true });
  const db = new DatabaseSync(path.join(dataDir, 'filenest.sqlite'));
  db.exec(`PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000;
    CREATE TABLE IF NOT EXISTS folders (id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE, createdAt TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS files (
      id TEXT PRIMARY KEY, folderId TEXT NOT NULL REFERENCES folders(id), name TEXT NOT NULL,
      caption TEXT, mimeType TEXT NOT NULL, category TEXT NOT NULL, size INTEGER NOT NULL,
      path TEXT NOT NULL UNIQUE, digest TEXT NOT NULL, createdAt TEXT NOT NULL, modifiedAt TEXT NOT NULL,
      trashed INTEGER NOT NULL DEFAULT 0);
    CREATE INDEX IF NOT EXISTS files_folder ON files(folderId, trashed, createdAt);`);
  const app = express();
  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '64kb' }));
  const upload = multer({ dest: tempDir, limits: { fileSize: maxUploadBytes, files: 1, fields: 5, fieldSize: 16384 } });
  const folderJson = row => ({ folderId: row.id, code: row.code, createdAt: row.createdAt });
  const fileJson = row => ({ ...row, downloadPath: `/files/${row.id}/content` });
  const getFile = id => db.prepare('SELECT * FROM files WHERE id = ? AND trashed = 0').get(id);
  const fail = (status, message) => Object.assign(new Error(message), { status });
  app.get('/health', (_req, res) => { db.prepare('SELECT 1').get(); res.json({ status: 'ok', storage: 'sqlite' }); });
  app.post('/folders', (_req, res) => {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (let attempt = 0; attempt < 30; attempt++) {
      const code = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join('');
      const row = { id: randomUUID(), code, createdAt: new Date().toISOString() };
      const result = db.prepare('INSERT OR IGNORE INTO folders VALUES (?, ?, ?)').run(row.id, code, row.createdAt);
      if (result.changes) return res.status(201).json(folderJson(row));
    }
    throw fail(503, 'Could not allocate a folder code. Retry.');
  });
  app.get('/folders/code/:code', (req, res) => {
    const row = db.prepare('SELECT * FROM folders WHERE code = ?').get(req.params.code.trim().toUpperCase());
    if (!row) throw fail(404, 'Folder not found on this server.');
    res.json(folderJson(row));
  });
  app.param('folderId', (req, _res, next, id) => {
    req.folder = db.prepare('SELECT * FROM folders WHERE id = ?').get(id);
    next(req.folder ? null : fail(404, 'Folder not found on this server.'));
  });
  app.get('/folders/:folderId', (req, res) => res.json(folderJson(req.folder)));
  app.get('/folders/:folderId/files', (req, res) => {
    res.json({ files: db.prepare('SELECT * FROM files WHERE folderId = ? AND trashed = 0 ORDER BY createdAt DESC, id').all(req.folder.id).map(fileJson) });
  });
  app.post('/folders/:folderId/files', upload.single('file'), async (req, res, next) => {
    let destination;
    let committed = false;
    try {
      if (!req.file) throw fail(400, 'A multipart file field named file is required.');
      const id = req.body.uploadId || randomUUID();
      if (typeof id !== 'string' || !/^[a-zA-Z0-9_-]{16,80}$/.test(id)) throw fail(400, 'Invalid uploadId.');
      const rawName = req.body.name || req.file.originalname;
      if (typeof rawName !== 'string') throw fail(400, 'Invalid filename.');
      const name = path.posix.basename(rawName.replace(/\\/g, '/'));
      if (!name || name === '.' || name === '..' || name.length > 255 || /[\x00-\x1f]/.test(name)) throw fail(400, 'Invalid filename.');
      const mimeType = req.file.mimetype || 'application/octet-stream';
      const category = req.body.category || categoryFor(name, mimeType);
      if (!['documents', 'images', 'videos', 'audio', 'other'].includes(category)) throw fail(400, 'Invalid category.');
      if (req.body.caption != null && typeof req.body.caption !== 'string') throw fail(400, 'Invalid caption.');
      const hash = createHash('sha256');
      for await (const chunk of fs.createReadStream(req.file.path)) hash.update(chunk);
      const digest = hash.digest('hex');
      // No awaits between checking this ID and committing: concurrent retries cannot overwrite a file.
      const existing = db.prepare('SELECT * FROM files WHERE id = ?').get(id);
      if (existing) {
        if (existing.trashed || existing.folderId !== req.folder.id || existing.digest !== digest || existing.name !== name || existing.caption !== (req.body.caption || null) || existing.category !== category || existing.mimeType !== mimeType) throw fail(409, 'Upload ID is already used by a different file.');
        return res.json(fileJson(existing));
      }
      const relativePath = path.posix.join('uploads', req.folder.id, category, id);
      destination = path.join(dataDir, relativePath);
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      fs.renameSync(req.file.path, destination);
      const now = new Date().toISOString();
      db.prepare('INSERT INTO files (id,folderId,name,caption,mimeType,category,size,path,digest,createdAt,modifiedAt) VALUES (?,?,?,?,?,?,?,?,?,?,?)')
        .run(id, req.folder.id, name, req.body.caption || null, mimeType, category, req.file.size, relativePath, digest, now, now);
      committed = true;
      res.status(201).json(fileJson(getFile(id)));
    } catch (error) { next(error); }
    finally {
      if (req.file) fs.rmSync(req.file.path, { force: true });
      if (destination && !committed) fs.rmSync(destination, { force: true });
    }
  });
  app.get('/files/:id', (req, res) => {
    const row = getFile(req.params.id);
    if (!row) throw fail(404, 'File not found.');
    res.json(fileJson(row));
  });
  app.get('/files/:id/content', (req, res, next) => {
    const row = getFile(req.params.id);
    if (!row) throw fail(404, 'File not found.');
    res.set('X-Content-Type-Options', 'nosniff');
    res.download(path.join(dataDir, row.path), row.name, { headers: { 'Content-Type': row.mimeType } }, error => { if (error) next(error); });
  });
  app.delete('/folders/:folderId/files/:id', (req, res) => {
    const result = db.prepare('UPDATE files SET trashed = 1, modifiedAt = ? WHERE id = ? AND folderId = ? AND trashed = 0')
      .run(new Date().toISOString(), req.params.id, req.folder.id);
    if (!result.changes) throw fail(404, 'File not found in this folder.');
    res.status(204).end();
  });
  app.use((_req, res) => res.status(404).json({ error: 'Endpoint not found.' }));
  app.use((error, _req, res, next) => {
    if (res.headersSent) return next(error);
    const status = error.code === 'LIMIT_FILE_SIZE' ? 413 : error instanceof multer.MulterError ? 400 : error.status || 500;
    if (status === 500) console.error(error);
    res.status(status).json({ error: status === 500 ? 'Server storage error.' : error.message });
  });
  return { app, db };
}
module.exports = { createApp };
