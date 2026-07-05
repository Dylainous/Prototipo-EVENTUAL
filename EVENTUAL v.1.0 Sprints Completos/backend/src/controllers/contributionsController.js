// src/controllers/contributionsController.js
const supabase = require('../config/supabase');

const CUOTA_ESTANDAR = 20.00;

/**
 * GET /api/contributions/pending
 * Lista socios activos con aportes pendientes del mes actual.
 * Solo Tesorero.
 */
const getPendingContributions = async (req, res) => {
  try {
    const ahora = new Date();
    const periodo = `${ahora.getFullYear()}-${String(ahora.getMonth() + 1).padStart(2, '0')}`;

    const { data: socios, error } = await supabase
      .from('profiles')
      .select('id, cedula, nombres, apellidos')
      .eq('estado', 'Activo');

    if (error) throw error;

    // Filtrar quiénes ya pagaron este período
    const { data: pagados } = await supabase
      .from('aportes_economicos')
      .select('socio_id')
      .eq('periodo', periodo)
      .eq('estado', 'Validado');

    const pagadosIds = new Set((pagados || []).map(p => p.socio_id));
    const pendientes = socios.filter(s => !pagadosIds.has(s.id));

    return res.status(200).json({ pendientes, cuota_estandar: CUOTA_ESTANDAR, periodo });
  } catch (err) {
    console.error('[contributions.getPending]', err);
    return res.status(500).json({ error: 'Error al obtener aportes pendientes' });
  }
};

/**
 * POST /api/contributions
 * Registrar aporte de un socio. Solo Tesorero.
 * Body: { socio_id, metodo_pago, monto, fecha_pago, observaciones, comprobante?, estado }
 */
const registerContribution = async (req, res) => {
  const { socio_id, metodo_pago, monto, fecha_pago, observaciones, comprobante, estado } = req.body;

  try {
    const ahora = new Date();
    const periodo = `${ahora.getFullYear()}-${String(ahora.getMonth() + 1).padStart(2, '0')}`;

    // Verificar duplicado
    const { data: dup } = await supabase
      .from('aportes_economicos')
      .select('id')
      .eq('socio_id', socio_id)
      .eq('periodo', periodo)
      .eq('estado', 'Validado')
      .single();

    if (dup) return res.status(409).json({ error: 'El socio ya tiene un aporte validado en este período' });

    // Validar monto
    if (!monto || monto <= 0) return res.status(400).json({ error: 'Monto inválido' });

    if (monto < CUOTA_ESTANDAR && estado === 'Validado') {
      return res.status(400).json({
        error: `El monto (${monto}) es menor a la cuota estándar (${CUOTA_ESTANDAR}). Requiere confirmación.`,
        requiere_confirmacion: true,
      });
    }

    const { data, error } = await supabase
      .from('aportes_economicos')
      .insert({
        socio_id,
        tesorero_id: req.user.id,
        metodo_pago,
        monto,
        fecha_pago,
        observaciones,
        comprobante: comprobante || null,
        estado: estado || 'Validado',
        periodo,
        saldo_pendiente: CUOTA_ESTANDAR - monto,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      message: 'Aporte registrado y validado exitosamente',
      aporte: data,
    });
  } catch (err) {
    console.error('[contributions.register]', err);
    return res.status(500).json({ error: 'Error al registrar el aporte' });
  }
};

module.exports = { getPendingContributions, registerContribution };