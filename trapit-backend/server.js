require('dotenv').config();
const express = require('express');
const cors    = require('cors');

// Init DB (creates all tables including capture_events with image_url)
require('./database/initDb');

const authRoutes          = require('./routes/auth.routes');
const trapsRoutes         = require('./routes/traps.routes');
const eventsRoutes        = require('./routes/events.routes');
const notificationsRoutes = require('./routes/notifications.routes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '20mb' }));   // increased limit for base64 image payloads

// ── Health check ────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.send('TrapIT Backend is running');
});

// ── Routes ──────────────────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/traps',         trapsRoutes);
app.use('/api/events',        eventsRoutes);        // POST /api/events/trap-event  ← Pi calls this
app.use('/api/notifications', notificationsRoutes); // GET  /api/notifications       ← Flutter calls this

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`TrapIT Backend running on port ${PORT}`);
});
