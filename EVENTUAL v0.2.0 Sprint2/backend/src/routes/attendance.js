const express = require('express');
const { body, param } = require('express-validator');
const { confirmAttendance, getMyAttendance } = require('../controllers/attendanceController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate);

router.post(
  '/',
  authorize('Socio'),
  [
    body('evento_id').isUUID().withMessage('ID de evento inválido'),
    body('asiste').isBoolean().withMessage('Debe indicar si asiste (true/false)'),
    body('num_acompanantes').optional().isInt({ min: 0, max: 5 }),
  ],
  validateRequest,
  confirmAttendance
);

router.get('/:eventoId/mine', getMyAttendance);

module.exports = router;