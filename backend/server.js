// backend/server.js
const app = require('./src/app');
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`SlipTrack backend running on http://localhost:${PORT}`);
});
