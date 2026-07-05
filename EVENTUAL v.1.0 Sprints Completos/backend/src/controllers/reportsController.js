const supabase = require('../config/supabase');

// ── Helpers ───────────────────────────────────────────────

function _validateDateRange(fechaInicio, fechaFin) {
  if (fechaInicio && fechaFin && new Date(fechaInicio) > new Date(fechaFin)) {
    return 'Rango de fechas inválido. Verifique los valores ingresados.';
  }
  return null;
}

// ── CU-R01: Reporte Participación de Socios ───────────────

/**
 * GET /api/reports/participation
 * Query params: fecha_inicio, fecha_fin, tipo_evento, evento_id
 */
const getParticipationReport = async (req, res) => {
  const { fecha_inicio, fecha_fin, tipo_evento, evento_id } = req.query;

  const dateError = _validateDateRange(fecha_inicio, fecha_fin);
  if (dateError) return res.status(400).json({ error: dateError });

  try {
    // Obtener eventos con asistencia
    let query = supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, fecha, lugar, estado, total_presentes, tasa_participacion')
      .in('estado', ['Ejecutado', 'Cerrado'])
      .order('fecha', { ascending: false });

    if (fecha_inicio) query = query.gte('fecha', fecha_inicio);
    if (fecha_fin)    query = query.lte('fecha', fecha_fin);
    if (tipo_evento && tipo_evento !== 'Todos') query = query.eq('tipo_evento', tipo_evento);
    if (evento_id)    query = query.eq('id', evento_id);

    const { data: eventos, error } = await query;
    if (error) throw error;

    if (!eventos || eventos.length === 0) {
      return res.status(200).json({
        eventos: [],
        resumen: null,
        mensaje: 'No se encontraron eventos para los criterios seleccionados.',
      });
    }

    // Para cada evento obtener confirmados reales
    const eventosConDatos = await Promise.all(
      eventos.map(async (ev) => {
        const { count: confirmados } = await supabase
          .from('confirmaciones_asistencia')
          .select('*', { count: 'exact', head: true })
          .eq('evento_id', ev.id)
          .eq('asiste', true);

        const presentes = ev.total_presentes || 0;
        const conf = confirmados || 0;
        const tasa = conf > 0
          ? parseFloat(((presentes / conf) * 100).toFixed(2))
          : (ev.tasa_participacion || 0);

        return {
          id: ev.id,
          nombre: ev.nombre,
          tipo_evento: ev.tipo_evento,
          fecha: ev.fecha,
          lugar: ev.lugar,
          estado: ev.estado,
          socios_confirmados: conf,
          socios_presentes: presentes,
          tasa_participacion: tasa,
        };
      })
    );

    // Resumen general
    const totalConfirmados = eventosConDatos.reduce((a, e) => a + e.socios_confirmados, 0);
    const totalPresentes   = eventosConDatos.reduce((a, e) => a + e.socios_presentes, 0);
    const promedioParticipacion = totalConfirmados > 0
      ? parseFloat(((totalPresentes / totalConfirmados) * 100).toFixed(2))
      : 0;
    const eventoMayorImpacto = eventosConDatos.reduce(
      (max, e) => e.tasa_participacion > (max?.tasa_participacion || 0) ? e : max,
      null
    );

    return res.status(200).json({
      eventos: eventosConDatos,
      resumen: {
        total_socios_convocados: totalConfirmados,
        total_asistencia_fisica: totalPresentes,
        promedio_participacion: promedioParticipacion,
        evento_mayor_impacto: eventoMayorImpacto?.nombre || '-',
        total_eventos: eventosConDatos.length,
      },
    });
  } catch (err) {
    console.error('[reports.participation]', err);
    return res.status(500).json({ error: 'Error al generar el reporte de participación' });
  }
};

// ── CU-R02: Reporte Historial de Eventos ─────────────────

/**
 * GET /api/reports/history
 * Query params: fecha_inicio, fecha_fin, tipo_evento, estado
 */
const getHistoryReport = async (req, res) => {
  const { fecha_inicio, fecha_fin, tipo_evento, estado } = req.query;

  const dateError = _validateDateRange(fecha_inicio, fecha_fin);
  if (dateError) return res.status(400).json({ error: dateError });

  try {
    let query = supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, fecha, hora, lugar, estado, codigo_evento, total_presentes, presupuesto_total, total_gastos, tasa_participacion, fecha_cierre')
      .order('fecha', { ascending: false });

    if (fecha_inicio) query = query.gte('fecha', fecha_inicio);
    if (fecha_fin)    query = query.lte('fecha', fecha_fin);
    if (tipo_evento && tipo_evento !== 'Todos') query = query.eq('tipo_evento', tipo_evento);
    if (estado && estado !== 'Todos') query = query.eq('estado', estado);

    const { data: eventos, error } = await query;
    if (error) throw error;

    if (!eventos || eventos.length === 0) {
      return res.status(200).json({
        eventos: [],
        mensaje: 'No se encontraron eventos para los criterios seleccionados.',
        firmante: null,
      });
    }

    // Obtener nombre del presidente para firma
    const { data: presidente } = await supabase
      .from('profiles')
      .select('nombres, apellidos')
      .eq('rol_id', 2)
      .eq('estado', 'Activo')
      .single();

    const firmante = presidente
      ? `${presidente.nombres} ${presidente.apellidos}`
      : 'Presidente del Club';

    return res.status(200).json({
      eventos,
      firmante,
      generado_en: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[reports.history]', err);
    return res.status(500).json({ error: 'Error al generar el reporte de historial' });
  }
};

// ── CU-R03: Reporte de Liquidaciones ─────────────────────

/**
 * GET /api/reports/liquidations
 * Query params: fecha_inicio, fecha_fin, evento_id, estado_liquidacion
 */
const getLiquidationsReport = async (req, res) => {
  const { fecha_inicio, fecha_fin, evento_id, estado_liquidacion } = req.query;

  const dateError = _validateDateRange(fecha_inicio, fecha_fin);
  if (dateError) return res.status(400).json({ error: 'Los filtros seleccionados no son válidos.' });

  try {
    // Eventos ejecutados o cerrados
    let query = supabase
      .from('eventos')
      .select('id, nombre, tipo_evento, fecha, estado, presupuesto_total, total_gastos, total_presentes, tasa_participacion, fecha_cierre')
      .in('estado', ['Ejecutado', 'Cerrado'])
      .order('fecha', { ascending: false });

    if (fecha_inicio) query = query.gte('fecha', fecha_inicio);
    if (fecha_fin)    query = query.lte('fecha', fecha_fin);
    if (evento_id)    query = query.eq('id', evento_id);

    const { data: eventos, error } = await query;
    if (error) throw error;

    if (!eventos || eventos.length === 0) {
      return res.status(200).json({
        liquidaciones: [],
        resumen: null,
        mensaje: 'No se encontraron liquidaciones para los criterios seleccionados.',
      });
    }

    // Para cada evento calcular ingresos (aportes del período) y gastos
    const liquidaciones = await Promise.all(
      eventos.map(async (ev) => {
        // Gastos del evento
        const { data: gastos } = await supabase
          .from('gastos_evento')
          .select('categoria, monto')
          .eq('evento_id', ev.id);

        const totalGastos = (gastos || []).reduce(
          (sum, g) => sum + parseFloat(g.monto || 0), 0
        );

        // Aportes del período del evento como proxy de ingresos
        const periodoEvento = ev.fecha?.substring(0, 7); // YYYY-MM
        const { data: aportes } = await supabase
          .from('aportes_economicos')
          .select('monto')
          .eq('periodo', periodoEvento)
          .eq('estado', 'Validado');

        const totalIngresos = (aportes || []).reduce(
          (sum, a) => sum + parseFloat(a.monto || 0), 0
        );

        const saldoFinal = totalIngresos - totalGastos;
        const estadoLiquidacion = ev.estado === 'Cerrado' ? 'Cerrada' : 'Pendiente';
        const informacionParcial = !gastos?.length && !aportes?.length;

        // Filtrar por estado_liquidacion si se especifica
        if (estado_liquidacion && estado_liquidacion !== 'Todas') {
          if (estado_liquidacion !== estadoLiquidacion) return null;
        }

        return {
          evento_id: ev.id,
          nombre: ev.nombre,
          tipo_evento: ev.tipo_evento,
          fecha: ev.fecha,
          estado_evento: ev.estado,
          estado_liquidacion: estadoLiquidacion,
          presupuesto_total: ev.presupuesto_total || 0,
          total_ingresos: totalIngresos,
          total_gastos: totalGastos,
          saldo_final: saldoFinal,
          total_presentes: ev.total_presentes || 0,
          informacion_parcial: informacionParcial,
          detalle_gastos: gastos || [],
          fecha_cierre: ev.fecha_cierre,
        };
      })
    );

    const liquidacionesFiltradas = liquidaciones.filter(Boolean);

    if (liquidacionesFiltradas.length === 0) {
      return res.status(200).json({
        liquidaciones: [],
        resumen: null,
        mensaje: 'No se encontraron liquidaciones para los criterios seleccionados.',
      });
    }

    // Totales generales
    const totalIngresosGeneral = liquidacionesFiltradas.reduce((s, l) => s + l.total_ingresos, 0);
    const totalGastosGeneral   = liquidacionesFiltradas.reduce((s, l) => s + l.total_gastos, 0);
    const saldoGeneral         = totalIngresosGeneral - totalGastosGeneral;

    return res.status(200).json({
      liquidaciones: liquidacionesFiltradas,
      resumen: {
        total_eventos: liquidacionesFiltradas.length,
        total_ingresos: parseFloat(totalIngresosGeneral.toFixed(2)),
        total_gastos: parseFloat(totalGastosGeneral.toFixed(2)),
        saldo_general: parseFloat(saldoGeneral.toFixed(2)),
      },
      generado_en: new Date().toISOString(),
    });
  } catch (err) {
    console.error('[reports.liquidations]', err);
    return res.status(500).json({ error: 'Error al generar el reporte de liquidaciones' });
  }
};

module.exports = {
  getParticipationReport,
  getHistoryReport,
  getLiquidationsReport,
};