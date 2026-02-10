const db = require('./db');

db.serialize(() => {

  // USERS TABLE
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      email TEXT PRIMARY KEY,
      full_name TEXT,
      password_hash TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // TRAPS TABLE
  db.run(`
    CREATE TABLE IF NOT EXISTS traps (
      trap_id TEXT PRIMARY KEY,
      trap_name TEXT,
      status INTEGER DEFAULT 1,
      email TEXT NOT NULL,
      FOREIGN KEY (email) REFERENCES users(email)
    )
  `);

  // CAPTURE EVENTS TABLE
  db.run(`
    CREATE TABLE IF NOT EXISTS capture_events (
      serial_no INTEGER PRIMARY KEY AUTOINCREMENT,
      trap_id TEXT NOT NULL,
      animal_name TEXT,
      confidence_score REAL,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (trap_id) REFERENCES traps(trap_id)
    )
  `);

  // NOTIFICATION LOGS TABLE
  db.run(`
    CREATE TABLE IF NOT EXISTS notification_logs (
      serial_no INTEGER PRIMARY KEY AUTOINCREMENT,
      capture_serial_no INTEGER,
      message TEXT,
      sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (capture_serial_no)
        REFERENCES capture_events(serial_no)
    )
  `);

  db.run(`
      CREATE TABLE IF NOT EXISTS otps (
        email TEXT PRIMARY KEY,
        otp TEXT NOT NULL,
        expires_at INTEGER NOT NULL
      )
    `);

  console.log('All tables initialized successfully');
});

module.exports = db;