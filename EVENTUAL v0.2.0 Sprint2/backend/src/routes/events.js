// src/routes/events.js
const express = require('express');
const { getEvents, getEventById } = require('../controllers/eventsController');
const { authenticate, authorize } = require('../middleware/auth');

const { registerEvent } = require('../controllers/eventRegistrationController');


const router = express.Router();

// Todos los usuarios autenticados pueden ver eventos
router.use(authenticate);

// GET /api/events?tipo=Social&year=2025&month=6
router.get('/', getEvents);

// GET /api/events/:id
router.get('/:id', getEventById);

// Solo Presidente puede registrar un evento
router.patch('/:id/register', authorize('Presidente'), registerEvent);

module.exports = router;
