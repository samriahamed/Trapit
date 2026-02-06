const db = require('../database/db');

db.all('SELECT email, full_name, created_at FROM users', (err, rows) => {
  if (err) {
    console.error('DB ERROR', err);
    process.exit(1);
  }
  console.log('USERS:', rows.length);
  rows.forEach(r => console.log(r));
  process.exit(0);
});
