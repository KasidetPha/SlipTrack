const Tesseract = require('tesseract.js');
const sharp = require('sharp');

async function preprocess(buffer) {
  return sharp(buffer)
    .rotate()
    .resize({ width: 1600, withoutEnlargement: true })
    .grayscale()
    .normalize()
    .linear(1.2, -10)
    .gamma(1.1)
    .toBuffer();
}

async function ocrImageBuffer(buffer) {
  const pre = await preprocess(buffer);

  const { data } = await Tesseract.recognize(pre, 'tha+eng', {
    tessedit_pageseg_mode: 6,
    preserve_interword_spaces: '1'
  });

  return {
    text: data.text || '',
    lines: (data.lines || []).map(l => ({
      text: l.text ?? '',
      bbox: l.bbox,
      confidence: l.confidence ?? null,
      words: (l.words || []).map(w => ({
        text: w.text ?? '',
        bbox: w.bbox,
        confidence: w.confidence ?? null
      }))
    }))
  };
}

module.exports = { ocrImageBuffer };
