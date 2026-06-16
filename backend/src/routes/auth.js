// src/routes/auth.js
const express = require('express');
const { body } = require('express-validator');
const { login } = require('../controllers/authController');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();

router.post(
  '/login',
  [
    body('cedula')
      .isLength({ min: 10, max: 10 })
      .withMessage('La cédula debe tener 10 dígitos')
      .isNumeric()
      .withMessage('La cédula solo puede contener números'),
    body('password')
      .notEmpty()
      .withMessage('La contraseña es requerida'),
  ],
  validateRequest,
  login
);

module.exports = router;
