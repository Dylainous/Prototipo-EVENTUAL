const supabase = require('../config/supabase');

/**
 * GET /api/broadcast/events
 * Lista eventos en estado 'Registrado' disponibles para difundir.
 * Solo Secretario.
 */
const getRegisteredEvents = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, fecha, hora, lugar, estado, codigo_evento')
      .eq('estado', 'Registrado')
      .order('fecha', { ascending: true });

    if (error) throw error;
    return res.status(200).json({ eventos: data || [] });
  } catch (err) {
    console.error('[broadcast.getRegistered]', err);
    return res.status(500).json({ error: 'Error al obtener eventos registrados' });
  }
};

/**
 * GET /api/broadcast/events/:id/template
 * Genera la plantilla de mensaje predeterminada con datos del evento
 * y nombres de los firmantes (Presidente, Tesorero, Secretario).
 */
const getTemplate = async (req, res) => {
  const { id } = req.params;
  try {
    const { data: evento, error: evErr } = await supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, fecha, hora, lugar, descripcion')
      .eq('id', id)
      .single();

    if (evErr || !evento) {
      return res.status(404).json({ error: 'Evento no encontrado' });
    }

    // Obtener firmantes por rol
    const { data: firmantes } = await supabase
      .from('profiles')
      .select('nombres, apellidos, roles(nombre)')
      .in('rol_id', [2, 3, 4]) // Presidente=2, Secretario=3, Tesorero=4
      .eq('estado', 'Activo');

    const presidente = firmantes?.find(f => f.roles?.nombre === 'Presidente');
    const secretario = firmantes?.find(f => f.roles?.nombre === 'Secretario');
    const tesorero   = firmantes?.find(f => f.roles?.nombre === 'Tesorero');

    const nombreFirmante = (p) =>
      p ? `${p.nombres} ${p.apellidos}` : 'Por designar';

    const plantilla =
`CLUB DE SUBOFICIALES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📢 CONVOCATORIA: ${evento.nombre.toUpperCase()}

Estimados socios,

Se les convoca a participar del siguiente evento:

🗓 Tipo     : ${evento.tipo_evento}
📅 Fecha    : ${evento.fecha}
🕐 Hora     : ${evento.hora}
📍 Lugar    : ${evento.lugar}
📝 Detalles : ${evento.descripcion || 'Ver información en la app'}

Les esperamos con puntualidad.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FIRMAS AUTORIZADAS

Presidente  : ${nombreFirmante(presidente)}
Tesorero    : ${nombreFirmante(tesorero)}
Secretario  : ${nombreFirmante(secretario)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`;

    return res.status(200).json({ plantilla, evento });
  } catch (err) {
    console.error('[broadcast.getTemplate]', err);
    return res.status(500).json({ error: 'Error al generar plantilla' });
  }
};

/**
 * POST /api/broadcast
 * Ejecuta la difusión: crea difusion, notificaciones para cada socio
 * activo y cambia estado del evento a 'Difundido'.
 * Body: { evento_id, mensaje, canales, es_inmediata, fecha_envio, recordatorios }
 */
const broadcast = async (req, res) => {
  const {
    evento_id,
    mensaje,
    canales,
    es_inmediata,
    fecha_envio,
    recordatorios = [],
  } = req.body;
  const secretarioId = req.user.id;

  try {
    // Verificar que el evento esté en estado 'Registrado'
    const { data: evento, error: evErr } = await supabase
      .from('eventos')
      .select('id, nombre, fecha, estado')
      .eq('id', evento_id)
      .single();

    if (evErr || !evento) {
      return res.status(404).json({ error: 'Evento no encontrado' });
    }
    if (evento.estado !== 'Registrado') {
      return res.status(400).json({
        error: 'Solo se pueden difundir eventos en estado Registrado',
      });
    }

    // Validar anticipación mínima de 15 días
    const fechaEvento = new Date(evento.fecha);
    const ahora = new Date();
    const diasAnticipacion = Math.floor(
      (fechaEvento - ahora) / (1000 * 60 * 60 * 24)
    );
    if (diasAnticipacion < 15) {
      return res.status(400).json({
        error: `La difusión debe realizarse con mínimo 15 días de anticipación. Faltan ${diasAnticipacion} días.`,
      });
    }

    // Calcular fechas de recordatorios
    const recordatoriosCalculados = (recordatorios || []).map((dias) => {
      const fecha = new Date(fechaEvento);
      fecha.setDate(fecha.getDate() - dias);
      return { dias_antes: dias, fecha_recordatorio: fecha.toISOString() };
    });

    // Registrar difusión
    const { data: difusion, error: difErr } = await supabase
      .from('difusiones')
      .insert({
        evento_id,
        secretario_id: secretarioId,
        mensaje,
        canales: canales || ['app'],
        fecha_envio: es_inmediata ? ahora.toISOString() : fecha_envio,
        es_inmediata: es_inmediata ?? true,
        recordatorios: recordatoriosCalculados,
        estado: 'Enviado',
        resultado: 'Difusión registrada correctamente',
      })
      .select()
      .single();

    if (difErr) throw difErr;

    // Obtener todos los socios activos
    const { data: socios } = await supabase
      .from('profiles')
      .select('id')
      .eq('estado', 'Activo');

    // Crear notificación interna para cada socio
    if (socios && socios.length > 0) {
      const notificaciones = socios.map((s) => ({
        socio_id: s.id,
        evento_id,
        difusion_id: difusion.id,
        mensaje,
        leida: false,
        fecha_envio: ahora.toISOString(),
      }));

      await supabase.from('notificaciones').insert(notificaciones);
    }

    // Cambiar estado del evento a 'Difundido'
    await supabase
      .from('eventos')
      .update({ estado: 'Difundido' })
      .eq('id', evento_id);

    return res.status(201).json({
      message: 'Información del evento difundida correctamente.',
      difusion_id: difusion.id,
      socios_notificados: socios?.length ?? 0,
      recordatorios_programados: recordatoriosCalculados.length,
    });
  } catch (err) {
    console.error('[broadcast.broadcast]', err);
    return res.status(500).json({
      error: 'Error al difundir la información del evento. Intente nuevamente.',
    });
  }
};

/**
 * GET /api/broadcast/notifications
 * Obtiene las notificaciones del socio autenticado.
 */
const getMyNotifications = async (req, res) => {
  const socioId = req.user.id;
  try {
    const { data, error } = await supabase
      .from('notificaciones')
      .select('id, mensaje, leida, fecha_envio, eventos(nombre, fecha, lugar)')
      .eq('socio_id', socioId)
      .order('fecha_envio', { ascending: false })
      .limit(50);

    if (error) throw error;
    return res.status(200).json({ notificaciones: data || [] });
  } catch (err) {
    return res.status(500).json({ error: 'Error al obtener notificaciones' });
  }
};

/**
 * PATCH /api/broadcast/notifications/:id/read
 * Marca una notificación como leída.
 */
const markAsRead = async (req, res) => {
  const { id } = req.params;
  try {
    await supabase
      .from('notificaciones')
      .update({ leida: true })
      .eq('id', id)
      .eq('socio_id', req.user.id);
    return res.status(200).json({ message: 'Notificación marcada como leída' });
  } catch (err) {
    return res.status(500).json({ error: 'Error al actualizar notificación' });
  }
};

module.exports = {
  getRegisteredEvents,
  getTemplate,
  broadcast,
  getMyNotifications,
  markAsRead,
};