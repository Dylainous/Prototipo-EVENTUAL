const express = require('express');
const {
  getParticipationReport,
  getHistoryReport,
  getLiquidationsReport,
} = require('../controllers/reportsController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/participation',  getParticipationReport);
router.get('/history',        getHistoryReport);
router.get('/liquidations',   getLiquidationsReport);

module.exports = router;