const express = require('express');
const router = express.Router();

// ดึงข้อมูล budget
router.get('/', (req, res) => {
  res.json({ budget: 5000 });
});

// อัปเดต budget
router.post('/update', (req, res) => {
  // รับข้อมูลจาก req.body
  res.json({ message: 'Budget updated!' });
});

router.get('/login', (req, res) => {
  res.send('Login route is working! (use POST for login)');
});

module.exports = router;