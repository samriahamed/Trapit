const express = require('express');
const router = express.Router();

// TEMP TEST ROUTE
router.get('/', (req, res) => {
  res.json({ message: 'Events API working' });
});

module.exports = router;
