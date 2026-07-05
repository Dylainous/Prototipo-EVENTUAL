const supabase = require('../config/supabase');

const getProviders = async (req, res) => {
  try {
    const { categoria, ciudad } = req.query;
    let query = supabase
      .from('proveedores')
      .select('*')
      .eq('activo', true)
      .order('nombre');

    if (categoria) query = query.eq('categoria', categoria);
    if (ciudad) query = query.ilike('ciudad', `%${ciudad}%`);

    const { data, error } = await query;
    if (error) throw error;
    return res.status(200).json({ proveedores: data || [] });
  } catch (err) {
    return res.status(500).json({ error: 'Error al obtener proveedores' });
  }
};

const addCandidateToEvent = async (req, res) => {
  const { evento_id, proveedor_id } = req.body;
  try {
    const { error } = await supabase
      .from('evento_proveedores_candidatos')
      .insert({ evento_id, proveedor_id });
    if (error) {
      if (error.code === '23505')
        return res.status(409).json({ error: 'El proveedor ya es candidato de este evento' });
      throw error;
    }
    return res.status(201).json({ message: 'Proveedor marcado como candidato' });
  } catch (err) {
    return res.status(500).json({ error: 'Error al agregar candidato' });
  }
};

const createProvider = async (req, res) => {
  const {
    nombre, categoria, telefono, email,
    direccion, ciudad, servicios_ofrecidos, calificacion
  } = req.body;

  try {
    // Verificar duplicado por nombre
    const { data: existing } = await supabase
      .from('proveedores')
      .select('id')
      .ilike('nombre', nombre.trim())
      .single();

    if (existing) {
      return res.status(409).json({
        error: 'El proveedor ya se encuentra registrado en el sistema.'
      });
    }

    // Validar calificación
    const cal = calificacion !== undefined
      ? parseFloat(calificacion) : 0;
    if (isNaN(cal) || cal < 0 || cal > 5) {
      return res.status(400).json({
        error: 'La calificación debe ser un valor entre 0 y 5.'
      });
    }

    const { data, error } = await supabase
      .from('proveedores')
      .insert({
        nombre: nombre.trim(),
        categoria,
        telefono: telefono || null,
        email: email || null,
        direccion: direccion || null,
        ciudad: ciudad || null,
        servicios_ofrecidos: servicios_ofrecidos || null,
        calificacion: cal,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      message: 'Proveedor registrado exitosamente.',
      proveedor: data,
    });
  } catch (err) {
    console.error('[providers.create]', err);
    return res.status(500).json({
      error: 'Error al registrar el proveedor. Intente nuevamente.'
    });
  }
};

module.exports = { getProviders, createProvider, addCandidateToEvent };