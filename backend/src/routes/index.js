const express = require('express');
const router = express.Router();
const authRoutes = require('./auth.routes');
const taskRoutes = require('./task.routes');
const userRoutes = require('./user.routes');
const reminderRoutes = require('./reminder.routes');

router.use('/auth', authRoutes);
router.use('/tasks', taskRoutes);
router.use('/users', userRoutes);
router.use('/reminders', reminderRoutes);

module.exports = router; 