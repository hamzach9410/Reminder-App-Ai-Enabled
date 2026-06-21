const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config/environment');

exports.register = async (req, res) => {
  try {
    const { username, email, password, firstName, lastName, deviceId } = req.body;
    
    const user = await User.create({
      username,
      email,
      password,
      firstName,
      lastName,
      lastFingerprint: deviceId || 'unknown'
    });

    const token = jwt.sign({ id: user._id }, config.jwtSecret, {
      expiresIn: config.jwtExpiration
    });

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password, deviceId } = req.body;

    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update fingerprint on each login for security tracking
    if (deviceId) {
      user.lastFingerprint = deviceId;
      await user.save();
    }

    const token = jwt.sign({ id: user._id }, config.jwtSecret, {
      expiresIn: config.jwtExpiration
    });

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
}; 