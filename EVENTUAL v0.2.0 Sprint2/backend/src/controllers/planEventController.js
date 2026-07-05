const supabase = require('../config/supabase');

/**
 * GET /api/plan-event/proposals
 * Lista propuestas en estado 'Pendiente' para que el Presidente las revise.
 */
const getPendingProposals = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('propuestas_evento')
      .select('*, profiles(nombres, apellidos, cedula)')
      .eq('estado', 'Pendiente')
      .order('fecha_registro', { ascending: false });
    if (error) throw error;
    return res.status(200).json({ propuestas: data || [] });
  } catch (err) {
    return res.status(500).json({ error: 'Error al obtener propuestas pendientes' });
  }
};

/**
 * POST /api/plan-event/approve/:propuestaId
 * Aprueba propuesta y crea el evento en estado 'Definido'.
 * Body: { fecha, hora, lugar, presupuesto_total, cupo_maximo }
 */
const approveAndSchedule = async (req, res) => {
  const { propuestaId } = req.params;
  const { fecha, hora, lugar, presupuesto_total, cupo_maximo } = req.body;

  try {
    // Verificar que la propuesta exista y esté pendiente
    const { data: propuesta, error: pErr } = await supabase
      .from('propuestas_evento').select('*').eq('id', propuestaId).single();
    if (pErr || !propuesta) return res.status(404).json({ error: 'Propuesta no encontrada' });
    if (propuesta.estado !== 'Pendiente')
      return res.status(400).json({ error: 'La propuesta ya fue procesada anteriormente' });

    // Verificar conflicto de fecha/hora con otros eventos definidos
    const { data: conflictos } = await supabase
      .from('eventos')
      .select('id')
      .eq('fecha', fecha)
      .eq('hora', hora)
      .in('estado', ['Definido', 'Registrado', 'Difundido']);

    if (conflictos && conflictos.length > 0) {
      return res.status(409).json({ error: 'La fecha y hora seleccionadas no están disponibles.' });
    }

    // Validar fecha futura
    if (new Date(`${fecha}T${hora}`) <= new Date()) {
      return res.status(400).json({ error: 'La fecha u hora del evento no son válidas.' });
    }

    // Crear el evento en estado 'Definido'
    const { data: evento, error: evErr } = await supabase
      .from('eventos')
      .insert({
        propuesta_id: propuestaId,
        nombre: propuesta.descripcion.substring(0, 100),
        tipo_evento: propuesta.tipo_evento,
        descripcion: propuesta.descripcion,
        fecha,
        hora,
        lugar,
        presupuesto_total: presupuesto_total || null,
        cupo_maximo: cupo_maximo || null,
        estado: 'Definido',
      })
      .select().single();
    if (evErr) throw evErr;

    // Actualizar estado de la propuesta a 'Aprobada'
    await supabase
      .from('propuestas_evento')
      .update({ estado: 'Aprobada' })
      .eq('id', propuestaId);

    return res.status(201).json({
      message: 'Evento definido correctamente.',
      evento,
    });
  } catch (err) {
    console.error('[planEvent.approve]', err);
    return res.status(500).json({ error: 'Error al definir el evento' });
  }
};

/**
 * POST /api/plan-event/reject/:propuestaId
 * Rechaza una propuesta.
 */
const rejectProposal = async (req, res) => {
  const { propuestaId } = req.params;
  try {
    const { error } = await supabase
      .from('propuestas_evento')
      .update({ estado: 'Rechazada' })
      .eq('id', propuestaId);
    if (error) throw error;
    return res.status(200).json({ message: 'Propuesta rechazada correctamente.' });
  } catch (err) {
    return res.status(500).json({ error: 'Error al rechazar la propuesta' });
  }
};

module.exports = { getPendingProposals, approveAndSchedule, rejectProposal };