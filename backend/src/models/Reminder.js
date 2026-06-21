const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true // This is the UUID from Flutter
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true
  },
  description: String,
  dateTime: Date,
  priority: {
    type: Number, // 0: low, 1: medium, 2: high
    default: 1
  },
  recurrence: {
    type: Number,
    default: 0
  },
  triggerType: String,
  status: {
    type: Number,
    default: 0 // pending
  },
  createdAt: Date,
  updatedAt: Date, // Critical for conflict resolution
  completedAt: Date,
  snoozedUntil: Date,
  customRecurrenceDays: Number,
  category: {
    type: Number,
    default: 0
  },
  calendarEventId: String
}, { timestamps: true });

// Index for high-performance syncing
reminderSchema.index({ userId: 1, id: 1 });
reminderSchema.index({ updatedAt: -1 });

module.exports = mongoose.model('Reminder', reminderSchema);
