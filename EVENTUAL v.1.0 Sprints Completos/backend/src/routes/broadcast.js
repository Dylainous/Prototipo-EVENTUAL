const express = require('express');
const { body } = require('express-validator');
const {
  getRegisteredEvents,
  getTemplate,
  broadcast,
  getMyNotifications,
  markAsRead,
} = require('../controllers/broadcastController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate);

// Secretario: listar eventos registrados
router.get('/events', authorize('Secretario'), getRegisteredEvents);

// Secretario: obtener plantilla
router.get('/events/:id/template', authorize('Secretario'), getTemplate);

// Secretario: ejecutar difusión
router.post(
  '/',
  authorize('Secretario'),
  [
    body('evento_id').isUUID().withMessage('ID de evento inválido'),
    body('mensaje').notEmpty().withMessage('Debe definir el contenido del mensaje antes de continuar.'),
    body('canales').isArray({ min: 1 }).withMessage('Debe seleccionar al menos un canal de difusión.'),
    body('es_inmediata').isBoolean(),
  ],
  validateRequest,
  broadcast
);

// Cualquier usuario autenticado: ver sus notificaciones
router.get('/notifications', getMyNotifications);
router.patch('/notifications/:id/read', markAsRead);

module.exports = router;