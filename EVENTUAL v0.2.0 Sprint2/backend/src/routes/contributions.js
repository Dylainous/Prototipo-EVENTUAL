const express = require('express');
const { body } = require('express-validator');
const { getPendingContributions, registerContribution } = require('../controllers/contributionsController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate, authorize('Tesorero'));

router.get('/pending', getPendingContributions);

router.post(
  '/',
  [
    body('socio_id').isUUID(),
    body('metodo_pago').isIn(['Efectivo', 'Transferencia']),
    body('monto').isFloat({ min: 0.01 }),
    body('fecha_pago').isDate(),
    body('estado').isIn(['Validado', 'Rechazado']),
  ],
  validateRequest,
  registerContribution
);

module.exports = router;