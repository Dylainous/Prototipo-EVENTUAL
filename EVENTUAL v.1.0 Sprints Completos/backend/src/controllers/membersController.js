// src/controllers/membersController.js
const supabase = require('../config/supabase');

/**
 * GET /api/members
 * Lista todos los socios con su rol.
 * Solo accesible por Presidente.
 */
const getMembers = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, cedula, nombres, apellidos, telefono, direccion, estado, fecha_ingreso, rol_id, roles(nombre)')
      .order('apellidos', { ascending: true });

    if (error) throw error;

    const members = data.map((p) => ({
      id: p.id,
      cedula: p.cedula,
      nombres: p.nombres,
      apellidos: p.apellidos,
      telefono: p.telefono,
      direccion: p.direccion,
      estado: p.estado,
      rol_id: p.rol_id,
      rol_nombre: p.roles?.nombre ?? '',
      fecha_ingreso: p.fecha_ingreso,
    }));

    return res.status(200).json({ members });
  } catch (err) {
    console.error('[members.getMembers]', err);
    return res.status(500).json({ error: 'Error al obtener socios' });
  }
};

/**
 * GET /api/members/roles
 * Devuelve lista de roles disponibles.
 */
const getRoles = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('roles')
      .select('id, nombre')
      .order('id');

    if (error) throw error;
    return res.status(200).json({ roles: data });
  } catch (err) {
    return res.status(500).json({ error: 'Error al obtener roles' });
  }
};

/**
 * POST /api/members
 * Agregar nuevo socio (crea usuario en auth.users + perfil en profiles).
 * Body: { cedula, nombres, apellidos, email, password, telefono?, direccion?, rol_id }
 */
const createMember = async (req, res) => {
  const { cedula, nombres, apellidos, email, password, telefono, direccion, rol_id } = req.body;

  try {
    // Crear usuario en Supabase Auth
    const { data: authUser, error: authError } =
      await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true, // confirmar automáticamente para prototipo
      });

    if (authError) {
      if (authError.message.includes('already')) {
        return res.status(409).json({ error: 'El correo ya está registrado' });
      }
      throw authError;
    }

    // Crear perfil en profiles
    const { error: profileError } = await supabase.from('profiles').insert({
      id: authUser.user.id,
      cedula,
      nombres,
      apellidos,
      telefono: telefono || null,
      direccion: direccion || null,
      rol_id: rol_id || 1,
      estado: 'Activo',
    });

    if (profileError) {
      // Rollback: eliminar usuario auth si falla el perfil
      await supabase.auth.admin.deleteUser(authUser.user.id);
      if (profileError.code === '23505') {
        return res.status(409).json({ error: 'La cédula ya está registrada' });
      }
      throw profileError;
    }

    return res.status(201).json({ message: 'Socio creado exitosamente' });
  } catch (err) {
    console.error('[members.createMember]', err);
    return res.status(500).json({ error: 'Error al crear socio' });
  }
};

/**
 * PUT /api/members/:id
 * Modificar datos personales de un socio.
 * Body: { nombres?, apellidos?, telefono?, direccion? }
 */
const updateMember = async (req, res) => {
  const { id } = req.params;
  const { nombres, apellidos, telefono, direccion } = req.body;

  try {
    const updates = {};
    if (nombres) updates.nombres = nombres;
    if (apellidos) updates.apellidos = apellidos;
    if (telefono !== undefined) updates.telefono = telefono;
    if (direccion !== undefined) updates.direccion = direccion;
    updates.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', id)
      .select('id, cedula, nombres, apellidos, telefono, direccion, estado, rol_id, roles(nombre)')
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Socio no encontrado' });

    return res.status(200).json({
      message: 'Socio actualizado correctamente',
      member: {
        id: data.id,
        cedula: data.cedula,
        nombres: data.nombres,
        apellidos: data.apellidos,
        telefono: data.telefono,
        direccion: data.direccion,
        estado: data.estado,
        rol_id: data.rol_id,
        rol_nombre: data.roles?.nombre ?? '',
      },
    });
  } catch (err) {
    console.error('[members.updateMember]', err);
    return res.status(500).json({ error: 'Error al actualizar socio' });
  }
};

/**
 * PATCH /api/members/:id/role
 * Asignar o cambiar el rol de un socio.
 * Body: { rol_id }
 */
const assignRole = async (req, res) => {
  const { id } = req.params;
  const { rol_id } = req.body;

  try {
    const { data, error } = await supabase
      .from('profiles')
      .update({ rol_id, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select('id, nombres, apellidos, rol_id, roles(nombre)')
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Socio no encontrado' });

    return res.status(200).json({
      message: `Rol asignado correctamente: ${data.roles?.nombre}`,
      member: {
        id: data.id,
        nombres: data.nombres,
        apellidos: data.apellidos,
        rol_id: data.rol_id,
        rol_nombre: data.roles?.nombre ?? '',
      },
    });
  } catch (err) {
    console.error('[members.assignRole]', err);
    return res.status(500).json({ error: 'Error al asignar rol' });
  }
};

/**
 * PATCH /api/members/:id/deactivate
 * Desactivar un socio (cambia estado a 'Inactivo').
 */
const deactivateMember = async (req, res) => {
  const { id } = req.params;

  try {
    // No permitir auto-desactivación
    if (id === req.user.id) {
      return res.status(400).json({ error: 'No puede desactivar su propia cuenta' });
    }

    const { data, error } = await supabase
      .from('profiles')
      .update({ estado: 'Inactivo', updated_at: new Date().toISOString() })
      .eq('id', id)
      .select('id, nombres, apellidos, estado')
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Socio no encontrado' });

    return res.status(200).json({
      message: `Socio ${data.nombres} ${data.apellidos} desactivado correctamente`,
    });
  } catch (err) {
    console.error('[members.deactivateMember]', err);
    return res.status(500).json({ error: 'Error al desactivar socio' });
  }
};

module.exports = { getMembers, getRoles, createMember, updateMember, assignRole, deactivateMember };
