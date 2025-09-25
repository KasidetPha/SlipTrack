// backend/src/app.js
const express = require('express');
const cors = require('cors');

const ocrRouter = require('./routes/ocr.route');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ ok: true, service: 'SlipTrack backend' });
});

app.use('/api/ocr', ocrRouter);

module.exports = app;
