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
  password: '', // ใส่รหัสผ่าน MySQL ของคุณ
  database: 'sliptrack',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const SECRET = "sliptrackVersion1"; // ใช้ในการสร้างและตรวจสอบ JWT

// Middleware ตรวจสอบ JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ message: "No token provided" });

  jwt.verify(token, SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: "Invalid or expired token" });

    req.user = user; // จะได้ user.id และ user.email
    next();
  });
}

// Route: Login
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // ดึงข้อมูลผู้ใช้
    const [rows] = await db.query(
      "SELECT * FROM users WHERE email = ?",
      [email]
    );

    if (rows.length === 0) {
      return res.status(400).json({ message: "User not found" });
    }

    const user = rows[0];

    // ตรวจสอบ password ถ้าใช้ bcrypt
    // const validPassword = await bcrypt.compare(password, user.password_hash);
    // if (!validPassword) return res.status(401).json({ message: "Invalid password" });

    // ถ้าใช้ SHA2 ใน DB
    const [checkPass] = await db.query(
      "SELECT * FROM users WHERE email = ? AND password_hash = SHA2(?, 256)",
      [email, password]
    );
    if (checkPass.length === 0) return res.status(401).json({ message: "Invalid password" });

    // สร้าง JWT
    const token = jwt.sign({ id: user.user_id, email: user.email }, SECRET, { expiresIn: "1h" });

    res.json({ message: "Login success", token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

app.post('/receipt_item/categories', authenticateToken, async (req,res) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const {month, year} = req.body;
    const finalMonth = month || (new Date().getMonth() + 1);
    const finalYear = year || (new Date().getFullYear());

    let prevMonth = finalMonth - 1;
    let prevYear = finalYear;
    if (prevMonth === 0) {
      prevMonth = 12;
      prevYear -= 1;
    }

    const [rows] = await db.query(`
      SELECT 
        categories.category_name,
        SUM(receipt_items.total_price) AS total_spent
      FROM receipt_items
      LEFT JOIN categories ON categories.category_id = receipt_items.category_id
      LEFT JOIN receipts ON receipts.receipt_id = receipt_items.receipt_id
      WHERE receipts.user_id = ?
        AND EXTRACT(MONTH FROM receipts.receipt_date) = ?
        AND EXTRACT(YEAR FROM receipts.receipt_date) = ?
      GROUP BY categories.category_name
      ORDER BY total_spent DESC
      LIMIT 2;
      `, [userId, month, year])
    console.log(rows);
    console.log(userId, finalMonth, finalYear);
    res.json(rows);
  } catch (err) {
    res.status(500).json({message: err.message});
  }
});

// app.post('/getMonthlyExpensesComparison', authenticateToken, async (req, res) => {
//   try {
//     const userId = req.user.id;
//     const now = new Date();
//     const {month, year} = req.body;
//     const finalMonth = month || (new Date().getMonth() + 1);
//     const finalYear = year || (new Date().getFullYear());

//     let prevMonth = finalMonth - 1;
//     let prevYear = finalYear;
//     if (prevMonth === 0) {
//       prevMonth = 12;
//       prevYear -= 1;
//     }

//     const [thisMonthRows] = await db.query(`
//       SELECT SUM(total_amount) as total_amount FROM receipts
//       WHERE user_id = ? AND EXTRACT(MONTH FROM receipt_date) = ? AND EXTRACT(YEAR FROM receipt_date) = ?;
//     `, [userId, finalMonth, finalYear])
//     const [lastMonthRows] = await db.query(`
//       SELECT SUM(total_amount) as total_amount FROM receipts
//       WHERE user_id = ? AND EXTRACT(MONTH FROM receipt_date) = ? AND EXTRACT(YEAR FROM receipt_date) = ?;
//     `, [userId, prevMonth, prevYear])

//     const thisMonthTotal = thisMonthRows[0].total_amount || 0
//     const lastMonthTotal = lastMonthRows[0].total_amount || 0

//     let percentChange = 0;
//     if (lastMonthTotal > 0) {
//       percentChange = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
//     }

//     res.json({
//       thisMonth: thisMonthTotal,
//       lastMonth: lastMonthTotal,
//       percentChange: percentChange.toFixed(2)
//     });

//     console.log(thisMonthRows);
//     console.log(lastMonthRows);
//   } catch (err) {
//     res.status(500).json({message: err.message})
//   }
// })

app.post('/monthlyTotal', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id;

    const {month, year} = req.body;

    const [rows] = await db.query(`
      SELECT SUM(total_amount) as total_amount FROM receipts
      WHERE user_id = ? AND EXTRACT(MONTH FROM receipt_date) = ? AND EXTRACT(YEAR FROM receipt_date) = ?;
      `, [userId, month, year])

    const total = rows?.[0].total_amount ?? 0;

    res.json({total});

    console.log('Fetch /monthlyTotal: ', month, year);
  } catch (err) {
    res.status(500).json({ message: err.message})
  }
})

// app.post('/')


// Route: ดึงข้อมูล receipt ของผู้ใช้
app.post('/receipt_item', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id; // เอา user id จาก token

    const {month, year} = req.body;
    const finalMonth = month || (new Date().getMonth() + 1);
    const finalYear = year || (new Date().getYear());
    const [rows] = await db.query(`
      SELECT
        u.full_name, ri.total_price, ri.item_name, r.receipt_date, ri.quantity
      FROM receipts r
      LEFT JOIN users u ON u.user_id = r.user_id
      LEFT JOIN receipt_items ri ON ri.receipt_id = r.receipt_id
      WHERE r.user_id = ?
        AND MONTH(r.receipt_date) = ?
        AND YEAR(r.receipt_date)  = ?
      ORDER BY r.receipt_date DESC;
    `, [userId, finalMonth, finalYear]);

    console.log("userId:", userId)
    console.log("month:", finalMonth)
    console.log("year:", finalYear)
    console.log("row:", rows)

    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Start server
app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
