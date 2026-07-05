const express = require('express');
const { body, param } = require('express-validator');
const { registerExpense, getExpensesByEvent } = require('../controllers/expensesController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate, authorize('Tesorero'));

router.post(
  '/',
  [
    body('evento_id').isUUID(),
    body('categoria').notEmpty(),
    body('monto').isFloat({ min: 0.01 }),
    body('fecha_gasto').isDate(),
    body('metodo_pago').notEmpty(),
    body('descripcion').notEmpty(),
    body('responsable').notEmpty(),
  ],
  validateRequest,
  registerExpense
);

router.get('/:eventoId', getExpensesByEvent);

module.exports = router;