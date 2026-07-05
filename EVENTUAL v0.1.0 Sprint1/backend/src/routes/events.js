// src/routes/events.js
const express = require('express');
const { getEvents, getEventById } = require('../controllers/eventsController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Todos los usuarios autenticados pueden ver eventos
router.use(authenticate);

// GET /api/events?tipo=Social&year=2025&month=6
router.get('/', getEvents);

// GET /api/events/:id
router.get('/:id', getEventById);

module.exports = router;
