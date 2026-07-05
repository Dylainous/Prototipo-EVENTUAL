// src/routes/proposals.js
const express = require('express');
const { body } = require('express-validator');
const { createProposal, getMyProposals } = require('../controllers/proposalsController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();

router.use(authenticate);

// POST /api/proposals  (solo Socio puede proponer)
router.post(
  '/',
  authorize('Socio'),
  [
    body('tipo_evento')
      .isIn(['Social', 'Deportivo'])
      .withMessage('Tipo de evento inválido'),
    body('descripcion')
      .isLength({ min: 50 })
      .withMessage('La descripción debe tener al menos 50 caracteres'),
    body('fecha_sugerida')
      .isDate()
      .withMessage('Fecha sugerida inválida (formato YYYY-MM-DD)'),
    body('justificacion')
      .notEmpty()
      .trim()
      .withMessage('La justificación es requerida'),
  ],
  validateRequest,
  createProposal
);

// GET /api/proposals/mine (cualquier socio autenticado)
router.get('/mine', getMyProposals);

module.exports = router;
