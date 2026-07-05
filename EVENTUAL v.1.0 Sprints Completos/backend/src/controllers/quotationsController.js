const supabase = require('../config/supabase');

const getQuotations = async (req, res) => {
  const { eventoId } = req.params;
  try {
    const { data, error } = await supabase
      .from('cotizaciones')
      .select('*, proveedores(nombre, categoria, calificacion)')
      .eq('evento_id', eventoId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return res.status(200).json({ cotizaciones: data || [] });
  } catch (err) {
    return res.status(500).json({ error: 'Error al obtener cotizaciones' });
  }
};

const createQuotation = async (req, res) => {
  const { evento_id, proveedor_id, tipo_servicio, descripcion, monto, moneda, fecha_validez, observaciones } = req.body;
  try {
    // Verificar fecha posterior a hoy
    if (new Date(fecha_validez) <= new Date()) {
      return res.status(400).json({ error: 'La fecha de validez debe ser posterior a la fecha actual.' });
    }

    // Calcular costo por persona usando cupo_maximo
    const { data: evento } = await supabase
      .from('eventos').select('cupo_maximo').eq('id', evento_id).single();
    const costo_por_persona = evento?.cupo_maximo
      ? parseFloat((monto / evento.cupo_maximo).toFixed(2))
      : null;

    const { data, error } = await supabase
      .from('cotizaciones')
      .insert({ evento_id, proveedor_id, tipo_servicio, descripcion, monto, moneda: moneda || 'USD', fecha_validez, observaciones, costo_por_persona })
      .select().single();
    if (error) throw error;
    return res.status(201).json({ message: 'Cotización registrada correctamente.', cotizacion: data });
  } catch (err) {
    return res.status(500).json({ error: 'Error al registrar la cotización. Intente nuevamente.' });
  }
};

const togglePreferred = async (req, res) => {
  const { id } = req.params;
  const { es_preferida } = req.body;
  try {
    const { error } = await supabase
      .from('cotizaciones').update({ es_preferida }).eq('id', id);
    if (error) throw error;
    return res.status(200).json({ message: 'Cotización actualizada' });
  } catch (err) {
    return res.status(500).json({ error: 'Error al actualizar cotización' });
  }
};

const evaluateCosts = async (req, res) => {
  const { eventoId } = req.params;
  try {
    const { data: evento } = await supabase
      .from('eventos').select('presupuesto_total, cupo_maximo').eq('id', eventoId).single();

    const { data: cotizaciones } = await supabase
      .from('cotizaciones')
      .select('*, proveedores(nombre, categoria, calificacion)')
      .eq('evento_id', eventoId)
      .eq('es_preferida', true);

    if (!cotizaciones || cotizaciones.length === 0) {
      return res.status(200).json({ mensaje: 'No existen cotizaciones disponibles para evaluar.', subtotales: {}, costo_total: 0, diferencia: 0, semaforo: 'verde' });
    }

    // Subtotales por categoría
    const subtotales = {};
    cotizaciones.forEach(c => {
      subtotales[c.tipo_servicio] = (subtotales[c.tipo_servicio] || 0) + parseFloat(c.monto);
    });
    const costo_total = Object.values(subtotales).reduce((a, b) => a + b, 0);
    const presupuesto = parseFloat(evento?.presupuesto_total || 0);
    const diferencia = presupuesto - costo_total;

    return res.status(200).json({
      cotizaciones_preferidas: cotizaciones,
      subtotales,
      costo_total,
      presupuesto_total: presupuesto,
      diferencia,
      semaforo: diferencia >= 0 ? 'verde' : 'rojo',
    });
  } catch (err) {
    return res.status(500).json({ error: 'Error al calcular costos' });
  }
};

module.exports = { getQuotations, createQuotation, togglePreferred, evaluateCosts };