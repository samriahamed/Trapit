const express = require('express');
const router  = express.Router();
const db      = require('../database/db');

// ─────────────────────────────────────────────────────────────────
// GET /api/notifications?limit=30
//
// Called by Flutter on app open to load unread notification list.
// Joins notification_logs with capture_events for full details.
// ─────────────────────────────────────────────────────────────────
router.get('/', (req, res) => {
  const { limit = 30 } = req.query;

  const query = `
    SELECT
      n.serial_no,
      n.capture_serial_no,
      n.message,
      n.sent_at,
      e.trap_id,
      e.animal_name,
      e.confidence_score,
      e.image_url,
      e.timestamp  AS captured_at
    FROM notification_logs n
    JOIN capture_events e ON n.capture_serial_no = e.serial_no
    ORDER BY n.serial_no DESC
    LIMIT ?
  `;

  db.all(query, [parseInt(limit)], (err, rows) => {
    if (err) {
      console.error('[Notifications] Fetch error:', err.message);
      return res.status(500).json({ error: 'Failed to fetch notifications' });
    }
    return res.json(rows);
  });
});


// ─────────────────────────────────────────────────────────────────
// GET /api/notifications/count
//
// Returns total notification count — Flutter badge counter.
// ─────────────────────────────────────────────────────────────────
router.get('/count', (req, res) => {
  db.get(`SELECT COUNT(*) AS count FROM notification_logs`, [], (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to count notifications' });
    }
    return res.json({ count: row.count });
  });
});

module.exports = router;
