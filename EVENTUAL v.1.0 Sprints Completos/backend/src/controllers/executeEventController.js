const supabase = require('../config/supabase');

/**
 * GET /api/execute-event/active
 * Lista eventos en estado 'Difundido' o 'Ejecutado' para el Presidente.
 */
const getActiveEvents = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, fecha, hora, lugar, estado, codigo_evento, total_presentes, tasa_participacion')
      .in('estado', ['Difundido', 'Ejecutado'])
      .order('fecha', { ascending: true });

    if (error) throw error;
    return res.status(200).json({ eventos: data || [] });
  } catch (err) {
    console.error('[execute.getActive]', err);
    return res.status(500).json({ error: 'Error al obtener eventos activos' });
  }
};

/**
 * GET /api/execute-event/:id/attendance-list
 * Lista socios confirmados y su estado de asistencia real.
 */
const getAttendanceList = async (req, res) => {
  const { id } = req.params;
  try {
    // Socios que confirmaron asistencia (CU-005)
    const { data: confirmados } = await supabase
      .from('confirmaciones_asistencia')
      .select('socio_id, asiste, num_acompanantes, profiles(nombres, apellidos, cedula)')
      .eq('evento_id', id)
      .eq('asiste', true);

    // Asistencia real ya registrada
    const { data: presentes } = await supabase
      .from('asistencia_real')
      .select('socio_id, tipo_registro, hora_ingreso, num_acompanantes_presentes')
      .eq('evento_id', id);

    const presentesIds = new Set((presentes || []).map(p => p.socio_id));

    const lista = (confirmados || []).map(c => ({
      socio_id: c.socio_id,
      nombres: c.profiles?.nombres,
      apellidos: c.profiles?.apellidos,
      cedula: c.profiles?.cedula,
      confirmados_acompanantes: c.num_acompanantes,
      presente: presentesIds.has(c.socio_id),
      detalle_presencia: presentes?.find(p => p.socio_id === c.socio_id) || null,
    }));

    // Socios activos que NO confirmaron (para registro manual fuera de lista)
    const { data: todosActivos } = await supabase
      .from('profiles')
      .select('id, nombres, apellidos, cedula')
      .eq('estado', 'Activo');

    const confirmadosIds = new Set((confirmados || []).map(c => c.socio_id));
    const noConfirmados = (todosActivos || [])
      .filter(s => !confirmadosIds.has(s.id))
      .map(s => ({
        socio_id: s.id,
        nombres: s.nombres,
        apellidos: s.apellidos,
        cedula: s.cedula,
        confirmados_acompanantes: 0,
        presente: presentesIds.has(s.id),
        detalle_presencia: presentes?.find(p => p.socio_id === s.id) || null,
      }));

    return res.status(200).json({
      confirmados: lista,
      no_confirmados: noConfirmados,
      total_confirmados: lista.length,
      total_presentes: presentes?.length ?? 0,
    });
  } catch (err) {
    console.error('[execute.getAttendanceList]', err);
    return res.status(500).json({ error: 'Error al obtener lista de asistencia' });
  }
};

/**
 * POST /api/execute-event/:id/register-attendance
 * Registra la asistencia real de un socio.
 * Body: { socio_id, tipo_registro, num_acompanantes_presentes, observaciones }
 */
const registerAttendance = async (req, res) => {
  const { id } = req.params;
  const { socio_id, tipo_registro = 'Manual', num_acompanantes_presentes = 0, observaciones } = req.body;

  try {
    // Verificar estado del evento
    const { data: evento } = await supabase
      .from('eventos')
      .select('id, estado, fecha')
      .eq('id', id)
      .single();

    if (!evento) return res.status(404).json({ error: 'Evento no encontrado' });
    if (!['Difundido', 'Ejecutado'].includes(evento.estado)) {
      return res.status(400).json({ error: 'El evento no está en un estado válido para registrar asistencia' });
    }

    // Verificar duplicado
    const { data: existing } = await supabase
      .from('asistencia_real')
      .select('id')
      .eq('evento_id', id)
      .eq('socio_id', socio_id)
      .single();

    if (existing) {
      return res.status(409).json({ error: 'Asistencia ya registrada para este participante' });
    }

    // Registrar asistencia
    const { data, error } = await supabase
      .from('asistencia_real')
      .insert({
        evento_id: id,
        socio_id,
        tipo_registro,
        num_acompanantes_presentes,
        hora_ingreso: new Date().toISOString(),
        registrado_por: req.user.id,
        observaciones,
      })
      .select()
      .single();

    if (error) throw error;

    // Cambiar estado del evento a 'Ejecutado' si aún estaba en 'Difundido'
    if (evento.estado === 'Difundido') {
      await supabase
        .from('eventos')
        .update({ estado: 'Ejecutado' })
        .eq('id', id);
    }

    // Actualizar contador total_presentes
    const { count } = await supabase
      .from('asistencia_real')
      .select('*', { count: 'exact', head: true })
      .eq('evento_id', id);

    await supabase
      .from('eventos')
      .update({ total_presentes: count || 0 })
      .eq('id', id);

    return res.status(201).json({
      message: 'Asistencia registrada correctamente',
      asistencia: data,
      total_presentes: count || 0,
    });
  } catch (err) {
    console.error('[execute.registerAttendance]', err);
    return res.status(500).json({ error: 'Error al registrar asistencia' });
  }
};

/**
 * GET /api/execute-event/:id/summary
 * Resumen del evento para el cierre: asistencia, gastos, tasa.
 */
const getEventSummary = async (req, res) => {
  const { id } = req.params;
  try {
    const { data: evento } = await supabase
      .from('eventos')
      .select('id, nombre, fecha, hora, lugar, estado, total_presentes, presupuesto_total, total_gastos')
      .eq('id', id)
      .single();

    if (!evento) return res.status(404).json({ error: 'Evento no encontrado' });

    const { count: totalConfirmados } = await supabase
      .from('confirmaciones_asistencia')
      .select('*', { count: 'exact', head: true })
      .eq('evento_id', id)
      .eq('asiste', true);

    const presentes = evento.total_presentes || 0;
    const confirmados = totalConfirmados || 0;
    const tasaParticipacion = confirmados > 0
      ? parseFloat(((presentes / confirmados) * 100).toFixed(2))
      : 0;

    const { data: gastos } = await supabase
      .from('gastos_evento')
      .select('categoria, monto')
      .eq('evento_id', id);

    return res.status(200).json({
      evento,
      resumen: {
        total_confirmados: confirmados,
        total_presentes: presentes,
        tasa_participacion: tasaParticipacion,
        total_gastos_registrados: gastos?.length ?? 0,
        monto_total_gastos: evento.total_gastos || 0,
        presupuesto_total: evento.presupuesto_total || 0,
      },
    });
  } catch (err) {
    console.error('[execute.getSummary]', err);
    return res.status(500).json({ error: 'Error al obtener resumen del evento' });
  }
};

/**
 * PATCH /api/execute-event/:id/close
 * Cierra formalmente el evento.
 */
const closeEvent = async (req, res) => {
  const { id } = req.params;
  try {
    const { data: evento } = await supabase
      .from('eventos')
      .select('id, nombre, estado, total_presentes')
      .eq('id', id)
      .single();

    if (!evento) return res.status(404).json({ error: 'Evento no encontrado' });
    if (evento.estado === 'Cerrado') {
      return res.status(400).json({ error: 'El evento ya fue cerrado previamente' });
    }
    if (evento.estado !== 'Ejecutado') {
      return res.status(400).json({ error: 'Solo se pueden cerrar eventos en estado Ejecutado' });
    }

    // Validar que haya al menos un asistente
    const { count: totalPresentes } = await supabase
      .from('asistencia_real')
      .select('*', { count: 'exact', head: true })
      .eq('evento_id', id);

    if (!totalPresentes || totalPresentes === 0) {
      return res.status(400).json({
        error: 'No se puede cerrar el evento sin registrar asistencia',
      });
    }

    // Calcular tasa de participación final
    const { count: totalConfirmados } = await supabase
      .from('confirmaciones_asistencia')
      .select('*', { count: 'exact', head: true })
      .eq('evento_id', id)
      .eq('asiste', true);

    const tasa = totalConfirmados > 0
      ? parseFloat(((totalPresentes / totalConfirmados) * 100).toFixed(2))
      : 100;

    // Cerrar el evento
    await supabase
      .from('eventos')
      .update({
        estado: 'Cerrado',
        fecha_cierre: new Date().toISOString(),
        tasa_participacion: tasa,
        total_presentes: totalPresentes,
      })
      .eq('id', id);

    return res.status(200).json({
      message: 'Evento cerrado exitosamente',
      tasa_participacion: tasa,
      total_presentes: totalPresentes,
    });
  } catch (err) {
    console.error('[execute.closeEvent]', err);
    return res.status(500).json({ error: 'Error al cerrar el evento' });
  }
};

module.exports = {
  getActiveEvents,
  getAttendanceList,
  registerAttendance,
  getEventSummary,
  closeEvent,
};