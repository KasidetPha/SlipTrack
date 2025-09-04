const express = require('express');
const router = express.Router();

// หน้าแรก
router.get('/', (req, res) => {
  res.send('Backend is running!');
});

// ตัวอย่าง route สำหรับ receipt_item
router.get('/receipt_item', (req, res) => {
  res.json([{ id: 1, name: 'Mock Item', amount: 100 }]);
});

module.exports = router;