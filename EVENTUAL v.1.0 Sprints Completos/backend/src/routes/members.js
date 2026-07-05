// src/routes/members.js
const express = require('express');
const { body, param } = require('express-validator');
const {
  getMembers,
  getRoles,
  createMember,
  updateMember,
  assignRole,
  deactivateMember,
} = require('../controllers/membersController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();

// Todos los endpoints requieren autenticación y rol Presidente
router.use(authenticate, authorize('Presidente'));

// GET /api/members
router.get('/', getMembers);

// GET /api/members/roles
router.get('/roles', getRoles);

// POST /api/members
router.post(
  '/',
  [
    body('cedula').isLength({ min: 10, max: 10 }).isNumeric().withMessage('Cédula inválida'),
    body('nombres').notEmpty().trim().withMessage('Nombres requeridos'),
    body('apellidos').notEmpty().trim().withMessage('Apellidos requeridos'),
    body('email').isEmail().withMessage('Email inválido'),
    body('password').isLength({ min: 8 }).withMessage('Contraseña mínimo 8 caracteres'),
    body('rol_id').isInt({ min: 1, max: 4 }).withMessage('Rol inválido'),
  ],
  validateRequest,
  createMember
);

// PUT /api/members/:id
router.put(
  '/:id',
  [
    param('id').isUUID().withMessage('ID inválido'),
    body('nombres').optional().notEmpty().trim(),
    body('apellidos').optional().notEmpty().trim(),
  ],
  validateRequest,
  updateMember
);

// PATCH /api/members/:id/role
router.patch(
  '/:id/role',
  [
    param('id').isUUID().withMessage('ID inválido'),
    body('rol_id').isInt({ min: 1, max: 4 }).withMessage('Rol inválido'),
  ],
  validateRequest,
  assignRole
);

// PATCH /api/members/:id/deactivate
router.patch(
  '/:id/deactivate',
  [param('id').isUUID().withMessage('ID inválido')],
  validateRequest,
  deactivateMember
);

module.exports = router;
