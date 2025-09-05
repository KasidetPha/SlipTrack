// เวลารัน รันใน Terminal "node server.js" *** รันด้วย node เวลาเซฟต้องรันยกเลิกแล้วรันใหม่
// ให้ใช้ nodemon ต้องติดตั้งก่อน ถึงจะใช้ nodemon ได้ ติดตั้ง "npm install nodemon" เวลารันแล้วพิมพ์ใน Terminal "nodemon server.js" 
// รัน nodemon เวลาเซฟแล้วจะไม่ต้องยกเลิกรันใหม่

const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// MySQL connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'sliptrack'
});

db.connect(err => {
  if (err) throw err;
  console.log("mysql connected!!");
});

// ตัวอย่าง route ใช้งาน database
app.get('/receipt_item', (req, res) => {
  db.query("SELECT * FROM receipt_items", (err, results) => {
    if (err) throw err;
    res.json(results);
  });
});

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

// Start server
app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
