// เวลารัน รันใน Terminal "node server.js" *** รันด้วย node เวลาเซฟต้องรันยกเลิกแล้วรันใหม่
// ให้ใช้ nodemon ต้องติดตั้งก่อน ถึงจะใช้ nodemon ได้ ติดตั้ง "npm install nodemon" เวลารันแล้วพิมพ์ใน Terminal "nodemon server.js" 
// รัน nodemon เวลาเซฟแล้วจะไม่ต้องยกเลิกรันใหม่


const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");

const app = express();

app.use(cors());
app.use(express.json());

// MySQL connection
const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'sliptrack',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const SECRET = "sliptrackVersion1";

// db.connect(err => {
//   if (err) throw err;
//   console.log("mysql connected!!");
// });

// login
app.post("/login", async (req, res) => {
  try {
    const {email, password} = req.body;
    
    const [rows] = await db.query("SELECT * FROM users WHERE email = ? AND password_hash = SHA2(?, 256)", [email, password]);
  
    if (rows.length === 0) {
      return res.status(400).json({"Message": "User not found"});
    }

    const user = rows[0];

    // const validPassword = await bcrypt.compare(password, user.password_hash);
    // if (!validPassword) {
    //   return res.status(401).json({message: "Invalid Password"});
    // }

    const token = jwt.sign({id: user.user_id, email: user.email}, SECRET, {expiresIn: "1h"});

    res.json({message: "Login Success", token});
  } catch (err) {
    console.error(err);
    res.status(500).json({message: "Server error"});
  }
})

app.get('/receipt_item', async (req, res) => {
  const [rows] = await db.query("SELECT * FROM receipt_items");
  res.json(rows);
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
