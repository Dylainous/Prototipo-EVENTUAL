const express = require('express');
const { body } = require('express-validator');
const {
  getProviders,
  createProvider,
  addCandidateToEvent,
} = require('../controllers/providersController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate);

// GET: Presidente, Tesorero y Secretario pueden consultar
router.get(
  '/',
  authorize('Presidente', 'Tesorero', 'Secretario'),
  getProviders
);

// POST: Solo Secretario registra proveedores (RF-10)
router.post(
  '/',
  authorize('Secretario'),
  [
    body('nombre')
      .notEmpty().withMessage('El nombre del proveedor es requerido.')
      .trim(),
    body('categoria')
      .isIn(['Alimentación','Sonido','Decoración','Transporte',
             'Seguridad','Entretenimiento','Alojamiento','Otros'])
      .withMessage('Categoría inválida.'),
    body('email')
      .optional({ checkFalsy: true })
      .isEmail().withMessage('El correo electrónico no es válido.'),
    body('telefono')
      .optional({ checkFalsy: true })
      .isLength({ min: 7, max: 15 })
      .withMessage('El teléfono debe tener entre 7 y 15 caracteres.'),
    body('calificacion')
      .optional()
      .isFloat({ min: 0, max: 5 })
      .withMessage('La calificación debe estar entre 0 y 5.'),
  ],
  validateRequest,
  createProvider
);

// POST candidatos: Presidente y Tesorero
router.post(
  '/candidates',
  authorize('Presidente', 'Tesorero'),
  [
    body('evento_id').isUUID(),
    body('proveedor_id').isUUID(),
  ],
  validateRequest,
  addCandidateToEvent
);

module.exports = router;