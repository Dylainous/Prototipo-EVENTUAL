const express = require('express');
const { body } = require('express-validator');
const { getProviders, createProvider, addCandidateToEvent } = require('../controllers/providersController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate, authorize('Presidente', 'Tesorero'));

router.get('/', getProviders);

router.post('/',
  [
    body('nombre').notEmpty().withMessage('Nombre requerido'),
    body('categoria').isIn(['Alimentación','Sonido','Decoración','Transporte','Seguridad','Entretenimiento','Otros']),
  ],
  validateRequest, createProvider
);

router.post('/candidates', 
  [body('evento_id').isUUID(), body('proveedor_id').isUUID()],
  validateRequest, addCandidateToEvent
);

module.exports = router;