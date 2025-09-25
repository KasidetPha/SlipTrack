const router = require('express').Router();
const { listBudgets, createBudget } = require('../controllers/budget.controller');

router.get('/list', listBudgets);
router.post('/create', createBudget);

module.exports = router;
