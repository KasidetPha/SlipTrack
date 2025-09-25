// เดโม: ใช้ array ในหน่วยความจำ
const budgets = [];

function listBudgets(_req, res) {
  res.json({ success: true, items: budgets });
}

function createBudget(req, res) {
  const { name, amount } = req.body || {};
  if (!name || amount == null) return res.status(400).json({ success: false, message: 'name & amount required' });
  const item = { id: budgets.length + 1, name, amount: Number(amount) };
  budgets.push(item);
  res.status(201).json({ success: true, item });
}

module.exports = { listBudgets, createBudget };
