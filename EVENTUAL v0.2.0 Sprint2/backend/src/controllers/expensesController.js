// src/controllers/expensesController.js
const supabase = require('../config/supabase');

/**
 * POST /api/expenses
 * Registrar gasto de un evento. Solo Tesorero.
 */
const registerExpense = async (req, res) => {
  const { evento_id, categoria, monto, fecha_gasto, metodo_pago, descripcion, responsable, proveedor } = req.body;

  try {
    const { data: evento, error: evErr } = await supabase
      .from('eventos')
      .select('id, nombre, presupuesto_total, total_gastos')
      .eq('id', evento_id)
      .single();

    if (evErr || !evento) return res.status(404).json({ error: 'Evento no encontrado' });

    const totalGastosNuevo = (evento.total_gastos || 0) + monto;
    if (totalGastosNuevo > (evento.presupuesto_total || Infinity)) {
      return res.status(400).json({ error: 'Presupuesto total del evento excedido' });
    }

    const porcentaje = evento.presupuesto_total
      ? (totalGastosNuevo / evento.presupuesto_total) * 100
      : 0;

    const { data, error } = await supabase
      .from('gastos_evento')
      .insert({
        evento_id,
        categoria,
        monto,
        fecha_gasto,
        metodo_pago,
        descripcion,
        responsable,
        proveedor: proveedor || null,
        tesorero_id: req.user.id,
        fecha_registro: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    // Actualizar total_gastos del evento
    await supabase
      .from('eventos')
      .update({ total_gastos: totalGastosNuevo })
      .eq('id', evento_id);

    return res.status(201).json({
      message: 'Gasto registrado exitosamente',
      gasto: data,
      alerta_presupuesto: porcentaje >= 90
        ? `Atención: se ha utilizado el ${porcentaje.toFixed(1)}% del presupuesto`
        : null,
    });
  } catch (err) {
    console.error('[expenses.register]', err);
    return res.status(500).json({ error: 'Error al registrar el gasto' });
  }
};

/**
 * GET /api/expenses/:eventoId
 * Listar gastos de un evento.
 */
const getExpensesByEvent = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('gastos_evento')
      .select('*')
      .eq('evento_id', req.params.eventoId)
      .order('fecha_registro', { ascending: false });

    if (error) throw error;
    return res.status(200).json({ gastos: data || [] });
  } catch (err) {
    return res.status(500).json({ error: 'Error al obtener gastos' });
  }
};

module.exports = { registerExpense, getExpensesByEvent };