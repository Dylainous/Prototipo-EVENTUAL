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

const createProvider = async (req, res) => {
  const { nombre, categoria, telefono, email, direccion, ciudad, servicios_ofrecidos } = req.body;
  try {
    const { data, error } = await supabase
      .from('proveedores')
      .insert({ nombre, categoria, telefono, email, direccion, ciudad, servicios_ofrecidos })
      .select().single();
    if (error) throw error;
    return res.status(201).json({ message: 'Proveedor registrado', proveedor: data });
  } catch (err) {
    return res.status(500).json({ error: 'Error al registrar proveedor' });
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

module.exports = { getProviders, createProvider, addCandidateToEvent };