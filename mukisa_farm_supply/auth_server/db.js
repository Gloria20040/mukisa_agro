const Database = require('better-sqlite3');
const path = require('path');
const env = process.env;

const dbFile = env.DB_FILE || path.join(__dirname, 'auth.db');
const db = new Database(dbFile);

// initialize users table
db.prepare(`CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  created_at TEXT NOT NULL
)`).run();

module.exports = db;
