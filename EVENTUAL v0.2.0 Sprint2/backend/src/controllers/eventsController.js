// src/controllers/eventsController.js
const supabase = require('../config/supabase');

/**
 * GET /api/events?tipo=Social&year=2025&month=6
 * Consultar calendario de eventos (RF3).
 * Soporta filtrado por tipo y mes (Strategy pattern en frontend).
 */
const getEvents = async (req, res) => {
  try {
    const { tipo, year, month } = req.query;

    let query = supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, descripcion, fecha, hora, lugar, estado, propuesta_id')
      .in('estado', ['Definido', 'Registrado', 'Difundido', 'Ejecutado'])
      .order('fecha', { ascending: true });

    // Filtro por tipo de evento
    if (tipo && tipo !== '') {
      query = query.eq('tipo_evento', tipo);
    }

    // Filtro por mes/año
    if (year && month) {
      const y = parseInt(year);
      const m = parseInt(month);
      const firstDay = `${y}-${String(m).padStart(2, '0')}-01`;
      const lastDay = new Date(y, m, 0).toISOString().split('T')[0];
      query = query.gte('fecha', firstDay).lte('fecha', lastDay);
    }

    const { data, error } = await query;
    if (error) throw error;

    return res.status(200).json({ eventos: data || [] });
  } catch (err) {
    console.error('[events.getEvents]', err);
    return res.status(500).json({ error: 'Error al obtener eventos' });
  }
};

/**
 * GET /api/events/:id
 * Detalle de un evento específico.
 */
const getEventById = async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, descripcion, fecha, hora, lugar, estado, propuesta_id')
      .eq('id', id)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Este evento ya no está disponible' });
    }

    return res.status(200).json({ evento: data });
  } catch (err) {
    console.error('[events.getEventById]', err);
    return res.status(500).json({ error: 'Error al obtener el evento' });
  }
};

module.exports = { getEvents, getEventById };
