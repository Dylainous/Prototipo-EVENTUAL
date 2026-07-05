// src/controllers/attendanceController.js
const supabase = require('../config/supabase');

/**
 * POST /api/attendance
 * Confirmar asistencia de un socio a un evento.
 * Body: { evento_id, asiste (bool), num_acompanantes, acompanantes [], comentarios }
 */
const confirmAttendance = async (req, res) => {
  const socioId = req.user.id;
  const { evento_id, asiste, num_acompanantes = 0, acompanantes = [], comentarios } = req.body;

  try {
    // Verificar que el evento exista y esté en estado válido
    const { data: evento, error: evError } = await supabase
      .from('eventos')
      .select('id, fecha, estado, cupo_maximo, plazas_confirmadas')
      .eq('id', evento_id)
      .single();

    if (evError || !evento) return res.status(404).json({ error: 'Evento no encontrado' });

    if (!['Registrado', 'Difundido'].includes(evento.estado)) {
      return res.status(400).json({ error: 'Este evento no admite confirmaciones' });
    }

    // Verificar plazo (mínimo 15 días antes)
    const hoy = new Date();
    const fechaEvento = new Date(evento.fecha);
    const diasRestantes = Math.floor((fechaEvento - hoy) / (1000 * 60 * 60 * 24));
    if (diasRestantes < 15) {
      return res.status(400).json({ error: 'El plazo de confirmación ha finalizado para este evento' });
    }

    // Verificar confirmación duplicada
    const { data: existing } = await supabase
      .from('confirmaciones_asistencia')
      .select('id')
      .eq('evento_id', evento_id)
      .eq('socio_id', socioId)
      .single();

    if (existing) {
      return res.status(409).json({ error: 'Usted ya ha registrado su asistencia para este evento' });
    }

    // Verificar cupo si asiste
    if (asiste) {
      const totalPersonas = 1 + num_acompanantes;
      const cupoDisponible = (evento.cupo_maximo || 999) - (evento.plazas_confirmadas || 0);
      if (totalPersonas > cupoDisponible) {
        return res.status(400).json({ error: 'No existe cupo disponible para la cantidad de personas seleccionadas' });
      }
    }

    // Registrar confirmación
    const { data, error } = await supabase
      .from('confirmaciones_asistencia')
      .insert({
        evento_id,
        socio_id: socioId,
        asiste,
        num_acompanantes: asiste ? num_acompanantes : 0,
        acompanantes: asiste ? acompanantes : [],
        comentarios,
        fecha_confirmacion: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    // Actualizar plazas confirmadas si asiste
    if (asiste) {
      await supabase
        .from('eventos')
        .update({ plazas_confirmadas: (evento.plazas_confirmadas || 0) + 1 + num_acompanantes })
        .eq('id', evento_id);
    }

    // Emitir evento Observer: ATTENDANCE_CONFIRMED
    return res.status(201).json({
      message: 'Confirmación registrada exitosamente',
      confirmacion: data,
    });
  } catch (err) {
    console.error('[attendance.confirm]', err);
    return res.status(500).json({ error: 'Error al registrar la confirmación' });
  }
};

/**
 * GET /api/attendance/:eventoId/mine
 * Ver mi confirmación para un evento específico.
 */
const getMyAttendance = async (req, res) => {
  const socioId = req.user.id;
  const { eventoId } = req.params;

  try {
    const { data, error } = await supabase
      .from('confirmaciones_asistencia')
      .select('*')
      .eq('evento_id', eventoId)
      .eq('socio_id', socioId)
      .single();

    if (error) return res.status(404).json({ confirmacion: null });
    return res.status(200).json({ confirmacion: data });
  } catch (err) {
    return res.status(500).json({ error: 'Error al consultar confirmación' });
  }
};

module.exports = { confirmAttendance, getMyAttendance };