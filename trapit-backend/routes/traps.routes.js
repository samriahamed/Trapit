const express = require('express');
const db = require('../database/db');
const axios = require('axios');

const router = express.Router();

/// ================= NEW — VERIFY TRAP DEVICE =================
router.get('/verify-device', async (req, res) => {
  try {
    const { trapIp, trapId } = req.query;

    if (!trapIp || !trapId) {
      return res.status(400).json({
        message: 'trapIp and trapId required',
      });
    }

    const url = `http://${trapIp}:8000/device/info`;

    console.log('Verifying trap at:', url);

    const response = await axios.get(url, {
      timeout: 8000,
    });

    const deviceTrapId =
      (response.data.trap_id || '').toString().trim().toLowerCase();

    const expectedTrapId =
      trapId.toString().trim().toLowerCase();

    if (deviceTrapId !== expectedTrapId) {
      return res.status(400).json({
        message: 'Trap ID mismatch',
        deviceTrapId,
      });
    }

    res.json({
      message: 'Trap verified successfully',
      device: response.data,
    });
  } catch (err) {
    console.error('VERIFY DEVICE ERROR:', err.message);

    res.status(500).json({
      message: 'Unable to verify trap device',
    });
  }
});

/// ================= ADD NEW TRAP =================
router.post('/', (req, res) => {
  const { email, trapId, trapName } = req.body;
    console.log(" ADD TRAP HIT:", trapId);
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

/// ================= GET ALL TRAPS FOR USER =================
router.get('/user/:email', (req, res) => {
  const { email } = req.params;

  db.all(
    `SELECT trap_id AS trapId,
            trap_name AS trapName,
            status
     FROM traps
     WHERE email = ?`,
    [email],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ message: 'Database error' });
      }

      res.json(rows);
    }
  );
});

/// ================= UPDATED — UPDATE TRAP STATUS + CONTROL PI =================
router.put('/:trapId/status', async (req, res) => {
  const { trapId } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ message: 'Status required' });
  }

  try {
    // 1 Update database
    db.run(
      `UPDATE traps
       SET status = ?
       WHERE trap_id = ?`,
      [status, trapId],
      async function (err) {
        if (err) {
          return res.status(500).json({ message: 'Update failed' });
        }

        // 2 Send command to Raspberry Pi
        const trapIp = "10.30.7.108"; // later we will store per trap

        try {
          await axios.post(
            `http://${trapIp}:8000/device/set-status`,
            { status: status },
            {
              timeout: 5000,
              headers: {
                "Content-Type": "application/json",
              },
            }
          );
          console.log(`Pi updated for trap ${trapId}: ${status}`);
        } catch (e) {
          console.log("Pi control failed:", e.message);
          // NOTE: we still return success because DB updated
        }

        res.json({ message: 'Status updated' });
      }
    );
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

/// ================= DELETE TRAP =================
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