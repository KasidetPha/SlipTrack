// backend/src/controllers/ocr.controller.js
const sharp = require('sharp');
const Tesseract = require('tesseract.js');

const parseReceipt = require('../utils/parseReceipt');
const parseBankSlip = require('../utils/parseBankSlip');

async function ocrImageBuffer(buf) {
  const processed = await sharp(buf).rotate().grayscale().toBuffer();
  const { data: { text /*, words, lines*/ } } = await Tesseract.recognize(processed, 'tha+eng', {
    tessedit_pageseg_mode: 6,
  });
  return text;
}

exports.ocrReceipt = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success:false, error:'No file uploaded' });
    const text = await ocrImageBuffer(req.file.buffer);
    const receipt = parseReceipt(text); // wrapper แล้ว เรียกตรง ๆ ได้
    return res.json({ success:true, type:'RECEIPT', receipt, rawText:text });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ success:false, error:'OCR failed', details:e.message });
  }
};

exports.ocrTransfer = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success:false, error:'No file uploaded' });
    const text = await ocrImageBuffer(req.file.buffer);
    const slip = parseBankSlip(text);
    return res.json({ success:true, type:'BANK_TRANSFER', slip, rawText:text });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ success:false, error:'OCR failed', details:e.message });
  }
};
