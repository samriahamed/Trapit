require('dotenv').config();

const express = require('express');
const cors = require('cors');

// Init DB
require('./database/initDb');

const authRoutes = require('./routes/auth.routes');
const trapsRoutes = require('./routes/traps.routes');
// const eventsRoutes = require('./routes/events.routes');         // ⛔ TEMP DISABLED
// const notificationsRoutes = require('./routes/notifications.routes'); // ⛔ TEMP DISABLED

const app = express();

app.use(cors());
app.use(express.json());

/// HEALTH CHECK
app.get('/', (req, res) => {
  res.send('TrapIT Backend is running ✅');
});

/// ROUTES
app.use('/api/auth', authRoutes);
app.use('/api/traps', trapsRoutes);
// app.use('/api/events', eventsRoutes);              // ENABLE LATER
// app.use('/api/notifications', notificationsRoutes); // ENABLE LATER

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`TrapIT Backend running on port ${PORT}`);
});
