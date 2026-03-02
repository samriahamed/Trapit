const express = require('express');
const bcrypt = require('bcrypt');
const db = require('../database/db');
const { sendOTP } = require('../utils/email');

const router = express.Router();


// ================= REGISTER =================

router.post('/register', async (req, res) => {

  console.log("REGISTER REQUEST ARRIVED");
  console.log(req.body);

  const { email, fullName, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password required' });
  }

  try {
    console.log("HASHING PASSWORD...");
    const hash = await bcrypt.hash(password, 10);
    console.log("PASSWORD HASHED");

    console.log("INSERTING USER INTO DB...");
    db.run(
      `INSERT INTO users (email, full_name, password_hash)
       VALUES (?, ?, ?)`,
      [email, fullName || '', hash],
      function (err) {

        if (err) {

          console.error("REGISTER DB ERROR:", err);

          if (err.message.includes("UNIQUE")) {
            return res.status(400).json({
              message: 'User already exists'
            });
          }

          return res.status(500).json({
            message: 'Database error',
            error: err.message
          });
        }

        console.log("USER CREATED:", email);

        res.status(201).json({
          message: 'User registered successfully'
        });
      }
    );

  } catch (err) {

    console.error("REGISTER SERVER ERROR:", err);

    res.status(500).json({
      message: 'Server error'
    });
  }
});


// ================= LOGIN =================

router.post('/login', (req, res) => {
  console.log("LOGIN REQUEST ARRIVED");
  console.log(req.body);

  const { email, password } = req.body;

  console.log("FETCHING USER FROM DB...");
  db.get(
    `SELECT * FROM users WHERE email = ?`,
    [email],
    async (err, user) => {
      if (err) {
        console.error("LOGIN DB ERROR:", err);
        return res.status(500).json({ message: 'Database error' });
      }

      if (!user) {
        console.error("LOGIN FAILED: User not found", email);
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


// ================= UPDATE USER NAME =================

router.put('/update-name', (req, res) => {

  const { email, fullName } = req.body;

  if (!email || !fullName) {
    return res.status(400).json({
      message: 'Email and full name required'
    });
  }

  db.run(
    `UPDATE users
     SET full_name = ?
     WHERE email = ?`,
    [fullName, email],
    function (err) {

      if (err) {
        return res.status(500).json({
          message: 'Failed to update name'
        });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          message: 'User not found'
        });
      }

      res.json({
        message: 'Name updated successfully',
        fullName
      });
    }
  );
});


// ================= CHANGE PASSWORD =================

router.post('/change-password', async (req, res) => {

  const { email, currentPassword, newPassword } = req.body;

  if (!email || !currentPassword || !newPassword) {
    return res.status(400).json({
      message: 'Email, current password and new password required'
    });
  }

  try {

    db.get(
      `SELECT * FROM users WHERE email = ?`,
      [email],
      async (err, user) => {

        if (err) {
          return res.status(500).json({ message: 'Database error' });
        }

        if (!user) {
          return res.status(404).json({ message: 'User not found' });
        }

        const match = await bcrypt.compare(
          currentPassword,
          user.password_hash
        );

        if (!match) {
          return res.status(401).json({
            message: 'Current password is incorrect'
          });
        }

        const hash = await bcrypt.hash(newPassword, 10);

        db.run(
          `UPDATE users SET password_hash = ? WHERE email = ?`,
          [hash, email],
          function (err) {

            if (err) {
              return res.status(500).json({
                message: 'Failed to update password'
              });
            }

            res.json({
              message: 'Password changed successfully'
            });
          }
        );
      }
    );

  } catch (err) {
    res.status(500).json({
      message: 'Server error'
    });
  }
});


// ================= VALIDATE USER SESSION =================

router.get('/validate-user/:email', (req, res) => {
  const { email } = req.params;

  db.get(
    `SELECT email FROM users WHERE email = ?`,
    [email],
    (err, user) => {
      if (err) {
        return res.status(500).json({ message: 'Database error' });
      }

      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }

      return res.status(200).json({ valid: true });
    }
  );
});


// ================= FORGOT PASSWORD - SEND OTP =================

router.post('/forgot-password/send-otp', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email required' });
  }

  db.get(`SELECT * FROM users WHERE email = ?`, [email], async (err, user) => {
    if (err) {
      return res.status(500).json({ message: 'Database error' });
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000;

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
          return res.json({ message: 'OTP sent to email' });
        } catch (e) {
          console.error("EMAIL ERROR:", e);
          return res.status(500).json({ message: 'Failed to send OTP email' });
        }
      }
    );
  });
});

// ================= FORGOT PASSWORD - VERIFY OTP =================

router.post('/forgot-password/verify-otp', (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({ message: 'Email and OTP required' });
  }

  db.get(
    `SELECT * FROM otps WHERE email = ?`,
    [email],
    (err, row) => {

      if (err) {
        return res.status(500).json({ message: 'Database error' });
      }

      if (!row) {
        return res.status(400).json({ message: 'OTP not found' });
      }

      const enteredOtp = otp.toString().trim();
      const storedOtp  = row.otp.toString().trim();

      if (enteredOtp !== storedOtp) {
        return res.status(400).json({ message: 'Invalid OTP' });
      }

      if (Date.now() > row.expires_at) {
        return res.status(400).json({ message: 'OTP expired' });
      }

      return res.json({ message: 'OTP verified' });
    }
  );
});

// ================= FORGOT PASSWORD - RESET PASSWORD =================

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

        if (err) {
          return res.status(500).json({ message: 'Database error' });
        }

        if (this.changes === 0) {
          return res.status(404).json({ message: 'User not found' });
        }

        // Delete OTP after successful reset
        db.run(`DELETE FROM otps WHERE email = ?`, [email]);

        return res.json({ message: 'Password successfully changed' });
      }
    );

  } catch (err) {
    return res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;