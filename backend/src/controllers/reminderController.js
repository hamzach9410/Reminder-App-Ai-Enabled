const Reminder = require('../models/Reminder');

/**
 * Bulk Sync Controller
 * Nuclear-Grade Upsert logic for high-performance mobile synchronization.
 */
exports.syncReminders = async (req, res) => {
  try {
    const { reminders } = req.body;
    const userId = req.user.id;

    if (!Array.isArray(reminders)) {
      return res.status(400).json({ success: false, message: 'Invalid reminders format' });
    }

    // Prepare bulk operations for high-efficiency persistence
    const operations = reminders.map(reminder => ({
      updateOne: {
        filter: { id: reminder.id, userId: userId },
        update: { 
          $set: { 
            ...reminder, 
            userId: userId,
            // Ensure dates are parsed correctly
            dateTime: reminder.dateTime ? new Date(reminder.dateTime) : null,
            updatedAt: reminder.updatedAt ? new Date(reminder.updatedAt) : new Date(),
            createdAt: reminder.createdAt ? new Date(reminder.createdAt) : new Date(),
          } 
        },
        upsert: true
      }
    }));

    if (operations.length > 0) {
      await Reminder.bulkWrite(operations);
    }

    res.json({
      success: true,
      message: `Successfully synced ${operations.length} reminders`,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Bulk sync failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during synchronization'
    });
  }
};

/**
 * Paginated reminder retrieval
 * Scalability safeguard for 5,000+ reminder stress test.
 */
exports.getReminders = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const reminders = await Reminder.find({ userId: req.user.id })
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Reminder.countDocuments({ userId: req.user.id });

    res.json({
      success: true,
      data: reminders,
      pagination: {
        total,
        page,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
