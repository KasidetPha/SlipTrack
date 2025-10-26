const express = require('express');
const router = express.Router();

// ตัวอย่าง login
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  // ตัวอย่างตรวจสอบ email/password (mock)
  if (email === 'user@email.com' && password === '123456') {
    res.json({ success: true, token: 'mock-token' });
  } else {
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});

module.exports = router;