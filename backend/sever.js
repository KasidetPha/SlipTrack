const express = require("express");
const app = express();
const port = 3000;

// route หลัก
app.get("/", (req, res) => {
  res.send("Hello Express Server!");
});

// เริ่มเซิร์ฟเวอร์
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});