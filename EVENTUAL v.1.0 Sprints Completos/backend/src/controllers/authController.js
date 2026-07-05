// src/controllers/authController.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

// Mapa en memoria para control de intentos fallidos
// { cedula: { count, blockedUntil } }
const loginAttempts = {};
const MAX_ATTEMPTS = 3;
const BLOCK_MINUTES = 15;

/**
 * POST /api/auth/login
 * Body: { cedula, password }
 *
 * Flujo según CU-001:
 *  1. Verificar bloqueo temporal
 *  2. Buscar usuario por cédula en profiles (join auth.users via Supabase admin)
 *  3. Verificar estado Activo
 *  4. Verificar contraseña con bcrypt
 *  5. Emitir JWT con id, nombres, apellidos, cedula, rol
 */
const login = async (req, res) => {
  const { cedula, password } = req.body;

  // 1. Verificar bloqueo
  const attempt = loginAttempts[cedula];
  if (attempt && attempt.blockedUntil && new Date() < attempt.blockedUntil) {
    const minLeft = Math.ceil((attempt.blockedUntil - new Date()) / 60000);
    return res.status(423).json({
      error: `Cuenta bloqueada por seguridad. Intente nuevamente en ${minLeft} minuto(s).`,
    });
  }

  try {
    // 2. Buscar perfil por cédula (join con roles)
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id, cedula, nombres, apellidos, telefono, estado, rol_id, roles(nombre)')
      .eq('cedula', cedula)
      .single();

    if (profileError || !profile) {
      _registerFailedAttempt(cedula, res);
      return; // respuesta ya enviada en _registerFailedAttempt
    }

    // 3. Verificar estado Activo
    if (profile.estado !== 'Activo') {
      return res.status(403).json({
        error: 'Su cuenta está inactiva. Contacte al presidente.',
      });
    }

    // 4. Obtener email de auth.users para verificar contraseña
    // Usamos signInWithPassword de Supabase Auth para verificar credenciales
    // El email está almacenado en auth.users; lo necesitamos para sign-in
    const { data: authData, error: signInError } =
      await supabase.auth.admin.getUserById(profile.id);

    if (signInError || !authData.user) {
      return res.status(500).json({ error: 'Error interno del servidor' });
    }

    const email = authData.user.email;

    // Verificar contraseña via Supabase Auth (retorna sesión si es correcta)
    const { error: pwError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (pwError) {
      _registerFailedAttempt(cedula, res);
      return;
    }

    // 5. Éxito: limpiar intentos y emitir JWT
    delete loginAttempts[cedula];

    const rolNombre = profile.roles?.nombre ?? 'Socio';

    const token = jwt.sign(
      {
        id: profile.id,
        cedula: profile.cedula,
        rol: rolNombre,
        rolId: profile.rol_id,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
    );

    return res.status(200).json({
      token,
      user: {
        id: profile.id,
        nombres: profile.nombres,
        apellidos: profile.apellidos,
        cedula: profile.cedula,
        rol: rolNombre,
      },
    });
  } catch (err) {
    console.error('[auth.login] Error:', err);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
};

function _registerFailedAttempt(cedula, res) {
  if (!loginAttempts[cedula]) {
    loginAttempts[cedula] = { count: 0, blockedUntil: null };
  }
  loginAttempts[cedula].count += 1;
  const count = loginAttempts[cedula].count;

  if (count >= MAX_ATTEMPTS) {
    const blockedUntil = new Date(Date.now() + BLOCK_MINUTES * 60 * 1000);
    loginAttempts[cedula].blockedUntil = blockedUntil;
    loginAttempts[cedula].count = 0;
    return res.status(423).json({
      error: `Cuenta bloqueada por seguridad. Intente nuevamente en ${BLOCK_MINUTES} minutos.`,
    });
  }

  return res.status(401).json({
    error: `Credenciales incorrectas. Intento ${count} de ${MAX_ATTEMPTS}.`,
  });
}

module.exports = { login };
