const express = require('express');
const { body, param } = require('express-validator');
const { getQuotations, createQuotation, togglePreferred, evaluateCosts } = require('../controllers/quotationsController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate, authorize('Presidente', 'Tesorero'));

router.get('/:eventoId', getQuotations);
router.get('/:eventoId/evaluate', evaluateCosts);

router.post('/',
  [
    body('evento_id').isUUID(),
    body('proveedor_id').isUUID(),
    body('tipo_servicio').notEmpty(),
    body('descripcion').notEmpty(),
    body('monto').isFloat({ min: 0.01 }),
    body('fecha_validez').isDate(),
  ],
  validateRequest, createQuotation
);

router.patch('/:id/preferred',
  [body('es_preferida').isBoolean()],
  validateRequest, togglePreferred
);

module.exports = router;