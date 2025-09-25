// backend/src/middleware/upload.js
const multer = require('multer');

// ใช้ memoryStorage เพื่อส่ง buffer เข้า OCR ได้ทันที (ไม่ต้องเขียนไฟล์ลงดิสก์)
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  // รับเฉพาะรูปภาพทั่วไป
  if (/^image\/(png|jpe?g|webp)$/i.test(file.mimetype)) cb(null, true);
  else cb(new Error('Unsupported file type'), false);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

module.exports = upload;
