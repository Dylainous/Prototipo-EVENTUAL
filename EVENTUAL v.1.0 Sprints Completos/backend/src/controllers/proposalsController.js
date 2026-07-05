// src/controllers/proposalsController.js
const supabase = require('../config/supabase');

/**
 * Genera número de seguimiento único: PROP-YYYYMMDD-XXXX
 */
function _generateTrackingNumber() {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `PROP-${date}-${rand}`;
}

/**
 * POST /api/proposals
 * Proponer un evento nuevo (RF4).
 * Solo socios autenticados.
 * Body: { tipo_evento, descripcion, fecha_sugerida, justificacion }
 */
const createProposal = async (req, res) => {
  const { tipo_evento, descripcion, fecha_sugerida, justificacion } = req.body;
  const socioId = req.user.id;

  try {
    const numeroSeguimiento = _generateTrackingNumber();

    const { data, error } = await supabase
      .from('propuestas_evento')
      .insert({
        socio_id: socioId,
        tipo_evento,
        descripcion,
        fecha_sugerida,
        justificacion,
        estado: 'Pendiente',
        numero_seguimiento: numeroSeguimiento,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      message: 'Propuesta registrada exitosamente',
      propuesta: {
        id: data.id,
        tipo_evento: data.tipo_evento,
        descripcion: data.descripcion,
        fecha_sugerida: data.fecha_sugerida,
        justificacion: data.justificacion,
        estado: data.estado,
        numero_seguimiento: data.numero_seguimiento,
        fecha_registro: data.fecha_registro,
      },
    });
  } catch (err) {
    console.error('[proposals.createProposal]', err);
    return res.status(500).json({ error: 'Error al registrar la propuesta' });
  }
};

/**
 * GET /api/proposals/mine
 * Obtener las propuestas del socio autenticado.
 */
const getMyProposals = async (req, res) => {
  const socioId = req.user.id;

  try {
    const { data, error } = await supabase
      .from('propuestas_evento')
      .select('id, tipo_evento, descripcion, fecha_sugerida, justificacion, estado, numero_seguimiento, fecha_registro')
      .eq('socio_id', socioId)
      .order('fecha_registro', { ascending: false });

    if (error) throw error;

    return res.status(200).json({ propuestas: data || [] });
  } catch (err) {
    console.error('[proposals.getMyProposals]', err);
    return res.status(500).json({ error: 'Error al obtener propuestas' });
  }
};

module.exports = { createProposal, getMyProposals };
