require('dotenv').config();
const bcrypt = require('bcrypt');
const db = require('./db');

async function createAdmin(username, password) {
  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  if (existing) {
    console.log('user exists');
    return;
  }
  const hash = await bcrypt.hash(password, 10);
  const info = db.prepare('INSERT INTO users (username, password_hash, role, created_at) VALUES (?, ?, ?, ?)')
    .run(username, hash, 'admin', new Date().toISOString());
  console.log('created admin id', info.lastInsertRowid);
}

const [,, username, password] = process.argv;
if (!username || !password) {
  console.log('Usage: node create_admin.js <username> <password>');
  process.exit(1);
}

createAdmin(username, password).then(() => process.exit(0)).catch(e => { console.error(e); process.exit(2); });
