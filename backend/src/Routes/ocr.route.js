// backend/src/routes/ocr.route.js
const router = require('express').Router();
const upload = require('../middleware/upload');
const { ocrReceipt, ocrTransfer } = require('../controllers/ocr.controller');

// ใบเสร็จร้านค้า
router.post('/receipt',  upload.single('file'), ocrReceipt);
// สลิปโอนเงินธนาคาร
router.post('/transfer', upload.single('file'), ocrTransfer);

module.exports = router;
