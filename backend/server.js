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
        categories.category_id,
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

app.get('/', (req, res) => {
  return res.json({msg: "success"})
});


// Route: ดึงข้อมูล receipt ของผู้ใช้
app.post('/receipt_item', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id; // เอา user id จาก token

    const {month, year} = req.body;
    const finalMonth = month || (new Date().getMonth() + 1);
    const finalYear = year || (new Date().getYear());
    const [rows] = await db.query(`
      SELECT
      ri.item_id, u.full_name, ri.total_price, ri.item_name, r.receipt_date, ri.quantity, ca.category_id
      FROM receipts r
      LEFT JOIN users u ON u.user_id = r.user_id
      LEFT JOIN receipt_items ri ON ri.receipt_id = r.receipt_id
      LEFT JOIN categories ca ON ca.category_id = ri.category_id
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

// นำตัวแรกของ Username มาทำ icon profile เป็นค่าเริ่มต้น
app.get('/firstUsername/icon', authenticateToken, async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({message: 'Unauthorized'});
    }

    const [rows] = await db.query(`
      SELECT LEFT(username, 1) AS initial FROM users WHERE user_id = ? LIMIT 1
      `, [userId]);

    const row = Array.isArray(rows) ? rows[0] : undefined;

    if (!row) {
      return res.status(404).json({ message: 'User not found'});
    }

    return res.status(200).json({username: row.initial});
  } catch (e) {
    console.error('GET /firstUsername/icon error:', e);
    return res.status(500).json({message: "Internal server error"});
  }
})

// category -> see all

// รายชื่อหมวดหมู่ทั้งหมด
// SELECT * FROM categories;

// จำนวนเงินของหมวดหมู่นั้นตามเดือนและปีและ ผู้ใช้ และ จำนวนรายการของหมวดหมู่นั้นๆ
app.post('/categories/summary', authenticateToken, async (req,res) => {
  try {
    const userId = req.user?.id;
    const {month, year} = req.body;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized'});
    }
    if (!month || !year) {
      return res.status(400).json({ message: 'Month and Year are required'});
    }

    const [rows] = await db.query(`
      SELECT 
        cate.category_id,
        cate.category_name, 
        COALESCE(SUM(
            CASE 
              WHEN re.user_id = ?
                    AND MONTH(re.receipt_date) = ?
                    AND YEAR(re.receipt_date) = ?
              THEN ri.total_price
            END
        ), 0) as total,
        COALESCE(COUNT(
            CASE 
              WHEN re.user_id = ?
                    AND MONTH(re.receipt_date) = ?
                    AND YEAR(re.receipt_date) = ?
              THEN ri.item_name
            END
        ),0) AS item_count
      FROM categories as cate
      LEFT JOIN receipt_items as ri ON ri.category_id = cate.category_id
      LEFT JOIN receipts as re ON re.receipt_id = ri.receipt_id 
      GROUP BY cate.category_name
      ORDER BY total DESC;
    `, [userId, month, year, userId, month, year, ]);

    const [totalThisMonthRows] = await db.query(`
      SELECT COALESCE(SUM(total_amount), 0) AS total_month FROM receipts AS re
      WHERE re.user_id = ?
      AND MONTH(re.receipt_date) = ?
      AND YEAR(re.receipt_date) = ?;
    `, [userId, month, year]);

    const totalMonth = totalThisMonthRows[0]?.total_month || 0;

    res.json({
      totalMonth,
      categories: rows
    })

  } catch (err) {
    console.error('POST /categories/summary error:', err);
    res.status(500).json({ message: 'Internal server error', error: err.message})
  }
})

// update item
app.put('/receipt_item/:id', authenticateToken, async (req, res) => {
  const conn = await db.getConnection();
  try {
    const userId = req.user?.id;
    const { id } = req.params;
    const { item_name, quantity, total_price, receipt_date, category_id} = req.body;

    if (!userId) return res.status(401).json({message: 'Unauthorized'});
    if (!id) return res.status(400).json({message: 'Missing item id'});

    if (
      typeof item_name !== 'string' ||
      typeof quantity !== 'number' ||
      typeof total_price !== 'number' ||
      typeof category_id !== 'number'
    ) {
      return res.status(400).json({ message: 'Invalid or missing fields'});
    }

    await conn.beginTransaction();

    const [[owner]] = await conn.query(`
      SELECT ri.receipt_id AS rid
      FROM receipt_items AS ri
      JOIN receipts AS re ON re.receipt_id = ri.receipt_id
      WHERE ri.item_id = ? AND re.user_id = ?
      FOR UPDATE
    `, [id, userId]);

    if (!owner) {
      await conn.rollback();
      return res.status(404).json({message: 'Item not found'});
    }

    await conn.query(`
      UPDATE receipt_items
      SET item_name = ?, quantity = ?, total_price = ?, category_id = ?
      WHERE item_id = ?
    `, [item_name, quantity, total_price, category_id, id]);

    if (receipt_date) {
      await conn.query(`
        UPDATE receipts SET receipt_date = ? WHERE receipt_id = ?
      `, [receipt_date, owner.rid])
    }

    const [[row]] = await conn.query(`
      SELECT 
        ri.item_id, ri.item_name, ri.quantity, ri.total_price, ri.category_id,
        re.receipt_date
      FROM receipt_items ri
      JOIN receipts re ON re.receipt_id = ri.receipt_id
      WHERE ri.item_id = ?
    `, [id]);

    await conn.commit();
    res.json(row || { ok: true });
  } catch (err) {
    await conn.rollback();
    console.log('PUT /receipt_item/:id error:', err);
    res.status(500).json({message: 'Internal server error', error: err.message});
  } finally {
    conn.release();
  }
})


// Start server
app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
