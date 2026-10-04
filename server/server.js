const path = require('node:path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { createApp } = require('./app');
const { app, db } = createApp();
const port = Number(process.env.PORT || 3001);
const server = app.listen(port, process.env.HOST || '0.0.0.0', () => {
  console.log(`FileNest local storage listening on port ${port}`);
});
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(() => { db.close(); process.exit(0); }));
}
