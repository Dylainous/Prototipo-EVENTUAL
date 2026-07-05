const express = require('express');
const { body, param } = require('express-validator');
const {
  getActiveEvents,
  getAttendanceList,
  registerAttendance,
  getEventSummary,
  closeEvent,
} = require('../controllers/executeEventController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate, authorize('Presidente'));

router.get('/active', getActiveEvents);
router.get('/:id/attendance-list', getAttendanceList);
router.get('/:id/summary', getEventSummary);

router.post(
  '/:id/register-attendance',
  [
    param('id').isUUID(),
    body('socio_id').isUUID().withMessage('ID de socio inválido'),
    body('tipo_registro').optional().isIn(['Manual', 'QR']),
    body('num_acompanantes_presentes').optional().isInt({ min: 0 }),
  ],
  validateRequest,
  registerAttendance
);

router.patch('/:id/close', closeEvent);

module.exports = router;