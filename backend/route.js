const express = require('express');


// import route
const route = require('./route');
const profileRoute = require('./routes/profileRoute');
const budgetRoute = require('./routes/budgetRoute');
const authRoute = require('./routes/authRoute');

// ใช้งาน route
app.use('/', route);
app.use('/profile', profileRoute);
app.use('/budget', budgetRoute);
app.use('/auth', authRoute);

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