const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  syncReminders,
  getReminders
} = require('../controllers/reminderController');

router.use(protect);

router.post('/sync', syncReminders);
router.get('/', getReminders);

module.exports = router;
