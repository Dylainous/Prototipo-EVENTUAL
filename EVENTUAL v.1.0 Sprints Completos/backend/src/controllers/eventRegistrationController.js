// src/controllers/eventRegistrationController.js
const supabase = require('../config/supabase');

function _generateEventCode(year, seq) {
  return `EVT-${year}-${String(seq).padStart(3, '0')}`;
}

/**
 * PATCH /api/events/:id/register
 * Formalizar un evento (cambiar estado Definido → Registrado).
 * Solo Presidente.
 */
const registerEvent = async (req, res) => {
  const { id } = req.params;

  try {
    const { data: evento, error: evErr } = await supabase
      .from('eventos')
      .select('id, nombre, estado, codigo_evento')
      .eq('id', id)
      .single();

    if (evErr || !evento) return res.status(404).json({ error: 'Evento no encontrado' });
    if (evento.estado !== 'Definido') {
      return res.status(400).json({ error: 'El evento ya fue registrado previamente o no está en estado Definido' });
    }

    // Generar código EVT-YYYY-NNN
    const year = new Date().getFullYear();
    const { count } = await supabase
      .from('eventos')
      .select('*', { count: 'exact', head: true })
      .like('codigo_evento', `EVT-${year}-%`);

    const codigoEvento = _generateEventCode(year, (count || 0) + 1);

    const { data, error } = await supabase
      .from('eventos')
      .update({
        estado: 'Registrado',
        codigo_evento: codigoEvento,
        fecha_registro: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.status(200).json({
      message: 'Evento registrado exitosamente',
      evento: data,
      codigo_evento: codigoEvento,
    });
  } catch (err) {
    console.error('[eventRegistration.register]', err);
    return res.status(500).json({ error: 'Error al registrar el evento' });
  }
};

module.exports = { registerEvent };