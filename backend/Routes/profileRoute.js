const express = require('express');
const router = express.Router();

// ดึงข้อมูลโปรไฟล์
router.get('/', (req, res) => {
  res.json({ id: 1, name: 'User', email: 'user@email.com' });
});

// แก้ไขโปรไฟล์
router.post('/edit', (req, res) => {
  // รับข้อมูลจาก req.body
  res.json({ message: 'Profile updated!' });
});

module.exports = router;