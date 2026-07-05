// src/index.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');
const membersRoutes = require('./routes/members');
const eventsRoutes = require('./routes/events');
const proposalsRoutes = require('./routes/proposals');

const attendanceRoutes     = require('./routes/attendance');
const contributionsRoutes  = require('./routes/contributions');
const expensesRoutes       = require('./routes/expenses');

const providersRoutes   = require('./routes/providers');
const quotationsRoutes  = require('./routes/quotations');
const planEventRoutes   = require('./routes/planEvent');

const app = express();

// ── Middleware global ────────────────────────────────────────
app.use(cors());
app.use(express.json());

// Rate limiting global (100 req/15min por IP)
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Demasiadas peticiones, intente más tarde' },
  })
);

// Rate limiting estricto para login (10 req/15min por IP)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Demasiados intentos de inicio de sesión' },
});

// ── Rutas ────────────────────────────────────────────────────
app.use('/api/auth', loginLimiter, authRoutes);
app.use('/api/members', membersRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/proposals', proposalsRoutes);

app.use('/api/attendance',    attendanceRoutes);
app.use('/api/contributions', contributionsRoutes);
app.use('/api/expenses',      expensesRoutes);

app.use('/api/providers',   providersRoutes);
app.use('/api/quotations',  quotationsRoutes);
app.use('/api/plan-event',  planEventRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

// Error handler global
app.use((err, req, res, next) => {
  console.error('[Unhandled error]', err);
  res.status(500).json({ error: 'Error interno del servidor' });
});

// ── Servidor ─────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend corriendo en http://localhost:${PORT}`);
  console.log(`📦 Ambiente: ${process.env.NODE_ENV || 'development'}`);
});
