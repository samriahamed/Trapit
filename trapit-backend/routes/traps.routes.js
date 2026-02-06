const express = require('express');
const db = require('../database/db');

const router = express.Router();

/// ➕ ADD NEW TRAP
router.post('/', (req, res) => {
  const { email, trapId, trapName } = req.body;

  if (!email || !trapId) {
    return res.status(400).json({ message: 'Email and Trap ID required' });
  }

  db.run(
    `INSERT INTO traps (trap_id, trap_name, status, email)
     VALUES (?, ?, ?, ?)`,
    [trapId, trapName || 'Backyard Trap', 'inactive', email],
    function (err) {
      if (err) {
        return res
          .status(400)
          .json({ message: 'Trap ID already exists' });
      }

      res.json({
        message: 'Trap added successfully',
        trap: {
          trapId,
          trapName: trapName || 'Backyard Trap',
          status: 'inactive',
        },
      });
    }
  );
});


/// 📄 GET ALL TRAPS FOR USER
router.get('/user/:email', (req, res) => {
  const { email } = req.params;

  db.all(
    `SELECT trap_id AS trapId,
            trap_name AS trapName,
            status
     FROM traps
     WHERE user_email = ?`,
    [email],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ message: 'Database error' });
      }

      res.json(rows);
    }
  );
});


/// 🔄 UPDATE TRAP STATUS (ON/OFF)
router.put('/:trapId/status', (req, res) => {
  const { trapId } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ message: 'Status required' });
  }

  db.run(
    `UPDATE traps
     SET status = ?
     WHERE trap_id = ?`,
    [status, trapId],
    function (err) {
      if (err) {
        return res.status(500).json({ message: 'Update failed' });
      }

      res.json({ message: 'Status updated' });
    }
  );
});


/// 🗑️ DELETE TRAP
router.delete('/:trapId', (req, res) => {
  const { trapId } = req.params;

  db.run(
    `DELETE FROM traps WHERE trap_id = ?`,
    [trapId],
    function (err) {
      if (err) {
        return res.status(500).json({ message: 'Delete failed' });
      }

      res.json({ message: 'Trap deleted successfully' });
    }
  );
});

module.exports = router;
