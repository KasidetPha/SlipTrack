const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const users = new Map(); // email -> { email, hash }

async function register(req, res) {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) return res.status(400).json({ success: false, message: 'email & password required' });
    if (users.has(email)) return res.status(409).json({ success: false, message: 'email already exists' });

    const hash = await bcrypt.hash(password, 10);
    users.set(email, { email, hash });
    res.json({ success: true, message: 'registered' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body || {};
    const u = users.get(email);
    if (!u) return res.status(401).json({ success: false, message: 'invalid credentials' });

    const ok = await bcrypt.compare(password, u.hash);
    if (!ok) return res.status(401).json({ success: false, message: 'invalid credentials' });

    const token = jwt.sign({ email }, process.env.JWT_SECRET, { expiresIn: '2h' });
    res.json({ success: true, token });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
}

function me(req, res) {
  try {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    if (!token) return res.status(401).json({ success: false, message: 'no token' });

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    res.json({ success: true, user: { email: payload.email } });
  } catch (e) {
    res.status(401).json({ success: false, message: 'invalid token' });
  }
}

module.exports = { register, login, me };
