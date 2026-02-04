const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../database/db');
const { sendOTP } = require('../utils/email');

const router = express.Router();

/// =======================
/// REGISTER
/// =======================
router.post('/register', async (req, res) => {
  const { email, fullName, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password required' });
  }

  try {
    const hash = await bcrypt.hash(password, 10);

    db.run(
      `INSERT INTO users (email, full_name, password_hash)
       VALUES (?, ?, ?)`,
      [email, fullName || '', hash],
      function (err) {
        if (err) {
          return res.status(400).json({ message: 'User already exists' });
        }

        res.json({ message: 'User registered successfully' });
      }
    );
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

/// =======================
/// LOGIN
/// =======================
router.post('/login', (req, res) => {
  const { email, password } = req.body;

  db.get(
    `SELECT * FROM users WHERE email = ?`,
    [email],
    async (err, user) => {
      if (err || !user) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const match = await bcrypt.compare(password, user.password_hash);

      if (!match) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      res.json({
        message: 'Login successful',
        user: {
          email: user.email,
          fullName: user.full_name,
        },
      });
    }
  );
});

/// =======================
/// SEND OTP (FORGOT PASSWORD)
/// =======================
router.post('/forgot-password/send-otp', (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email required' });
  }

  // Check user exists
  db.get(`SELECT * FROM users WHERE email = ?`, [email], async (err, user) => {
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    db.run(
      `INSERT OR REPLACE INTO otps (email, otp, expires_at)
       VALUES (?, ?, ?)`,
      [email, otp, expiresAt],
      async (err) => {
        if (err) {
          return res.status(500).json({ message: 'Failed to save OTP' });
        }

        try {
          await sendOTP(email, otp);
          res.json({ message: 'OTP sent to email' });
        } catch (e) {
          res.status(500).json({ message: 'Failed to send OTP email' });
        }
      }
    );
  });
});

/// =======================
/// VERIFY OTP
/// =======================
router.post('/forgot-password/verify-otp', (req, res) => {
  const { email, otp } = req.body;

  db.get(
    `SELECT * FROM otps WHERE email = ?`,
    [email],
    (err, row) => {
      if (!row) {
        return res.status(400).json({ message: 'OTP not found' });
      }

      if (row.otp !== otp) {
        return res.status(400).json({ message: 'Invalid OTP' });
      }

      if (Date.now() > row.expires_at) {
        return res.status(400).json({ message: 'OTP expired' });
      }

      res.json({ message: 'OTP verified' });
    }
  );
});

/// =======================
/// RESET PASSWORD (AFTER OTP)
/// =======================
router.post('/forgot-password/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;

  if (!email || !newPassword) {
    return res.status(400).json({ message: 'Email and new password required' });
  }

  try {
    const hash = await bcrypt.hash(newPassword, 10);

    db.run(
      `UPDATE users SET password_hash = ? WHERE email = ?`,
      [hash, email],
      function (err) {
        if (err || this.changes === 0) {
          return res.status(500).json({ message: 'Failed to update password' });
        }

        // Delete OTP after success
        db.run(`DELETE FROM otps WHERE email = ?`, [email]);

        res.json({ message: 'Password successfully changed' });
      }
    );
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
