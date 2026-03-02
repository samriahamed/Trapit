const express = require('express');
const router  = express.Router();
const db      = require('../database/db');

// ─────────────────────────────────────────────────────────────────
// POST /api/events/trap-event
//
// Called by the Raspberry Pi FastAPI server (server.py) when an
// animal is detected and the trap door has been closed.
//
// Body (JSON):
//   {
//     "trap_id":       "TRAP-ABC123",
//     "animal_name":   "monkey",
//     "confidence":    0.8731,
//     "captured_at":   "2026-02-22T11:07:31.423",
//     "image_url":     "/images/2026-02-22_11-07-31_monkey_0.87.jpg"
//   }
// ─────────────────────────────────────────────────────────────────
router.post('/trap-event', (req, res) => {
  const { trap_id, animal_name, confidence, captured_at, image_url } = req.body;

  // Validate required fields
  if (!trap_id || !animal_name || confidence === undefined) {
    return res.status(400).json({ error: 'trap_id, animal_name and confidence are required' });
  }

  const animalDisplay = animal_name
    .replace(/_/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase());   // "wild_boar" → "Wild Boar"

  const timestamp = captured_at || new Date().toISOString();

  // Step 1 — Insert capture event
  const insertEvent = `
    INSERT INTO capture_events (trap_id, animal_name, confidence_score, image_url, timestamp)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.run(insertEvent, [trap_id, animalDisplay, confidence, image_url || null, timestamp], function (err) {
    if (err) {
      console.error('[Events] DB insert error:', err.message);
      return res.status(500).json({ error: 'Failed to save capture event' });
    }

    const captureSerialNo = this.lastID;
    const message = `${animalDisplay} detected in trap ${trap_id}`;

    // Step 2 — Insert notification log
    const insertNotif = `
      INSERT INTO notification_logs (capture_serial_no, message)
      VALUES (?, ?)
    `;

    db.run(insertNotif, [captureSerialNo, message], (err2) => {
      if (err2) {
        console.error('[Events] Notification log error:', err2.message);
        // Non-fatal — still return success, event was saved
      }
    });

    console.log(`[Events] Saved: ${animalDisplay} (${(confidence * 100).toFixed(1)}%) trap=${trap_id} serial=${captureSerialNo}`);

    return res.status(200).json({
      success:          true,
      serial_no:        captureSerialNo,
      trap_id:          trap_id,
      animal_name:      animalDisplay,
      confidence_score: confidence,
      image_url:        image_url || null,
      timestamp:        timestamp,
      message:          message
    });
  });
});


// ─────────────────────────────────────────────────────────────────
// GET /api/events?trap_id=TRAP-ABC123&limit=50
//
// Called by Flutter to load the trapped history list.
// Returns events newest-first. Optionally filtered by trap_id.
// ─────────────────────────────────────────────────────────────────
router.get('/', (req, res) => {
  const { trap_id, limit = 50 } = req.query;

  let query  = `SELECT * FROM capture_events`;
  let params = [];

  if (trap_id) {
    query  += ` WHERE trap_id = ?`;
    params.push(trap_id);
  }

  query += ` ORDER BY serial_no DESC LIMIT ?`;
  params.push(parseInt(limit));

  db.all(query, params, (err, rows) => {
    if (err) {
      console.error('[Events] Fetch error:', err.message);
      return res.status(500).json({ error: 'Failed to fetch events' });
    }
    return res.json(rows);
  });
});


// ─────────────────────────────────────────────────────────────────
// GET /api/events/:serial_no
//
// Called by Flutter for the detail screen of a single event.
// ─────────────────────────────────────────────────────────────────
router.get('/:serial_no', (req, res) => {
  const { serial_no } = req.params;

  db.get(`SELECT * FROM capture_events WHERE serial_no = ?`, [serial_no], (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch event' });
    }
    if (!row) {
      return res.status(404).json({ error: 'Event not found' });
    }
    return res.json(row);
  });
});


// ─────────────────────────────────────────────────────────────────
// DELETE /api/events/:serial_no
//
// Delete a single event (optional — for app UI clear action).
// ─────────────────────────────────────────────────────────────────
router.delete('/:serial_no', (req, res) => {
  const { serial_no } = req.params;

  db.run(`DELETE FROM capture_events WHERE serial_no = ?`, [serial_no], function (err) {
    if (err) {
      return res.status(500).json({ error: 'Failed to delete event' });
    }
    return res.json({ success: true, deleted_serial_no: serial_no });
  });
});

module.exports = router;
