import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/reports_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.people), text: 'Participación'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Liquidaciones'),
          ]),
        ),
        body: const TabBarView(children: [
          _ParticipationTab(),
          _HistoryTab(),
          _LiquidationsTab(),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// TAB 1: PARTICIPACIÓN
// ════════════════════════════════════════════════════════
class _ParticipationTab extends StatefulWidget {
  const _ParticipationTab();
  @override State<_ParticipationTab> createState() => _ParticipationTabState();
}

class _ParticipationTabState extends State<_ParticipationTab> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoEvento = 'Todos';

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => isStart ? _fechaInicio = d : _fechaFin = d);
  }

  void _generate() {
    if (_fechaInicio != null && _fechaFin != null &&
        _fechaInicio!.isAfter(_fechaFin!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Filtros incorrectos. Verifique los datos ingresados.'),
        backgroundColor: Colors.red));
      return;
    }
    context.read<ReportsBloc>().add(ReportsGenerateParticipation(
      fechaInicio: _fechaInicio != null
          ? DateFormat('yyyy-MM-dd').format(_fechaInicio!) : null,
      fechaFin: _fechaFin != null
          ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : null,
      tipoEvento: _tipoEvento,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _FilterPanel(children: [
        Row(children: [
          Expanded(child: _DateButton(
            label: _fechaInicio == null ? 'Fecha inicio' : DateFormat('dd/MM/yy').format(_fechaInicio!),
            onTap: () => _pickDate(true),
          )),
          const SizedBox(width: 8),
          Expanded(child: _DateButton(
            label: _fechaFin == null ? 'Fecha fin' : DateFormat('dd/MM/yy').format(_fechaFin!),
            onTap: () => _pickDate(false),
          )),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _tipoEvento,
          decoration: const InputDecoration(labelText: 'Tipo de evento', isDense: true),
          items: ['Todos', 'Social', 'Deportivo']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _tipoEvento = v!),
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text('Generar Reporte'),
            onPressed: _generate,
          )),
      ]),
      Expanded(child: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) return const Center(child: CircularProgressIndicator());
          if (state is ReportsParticipationLoaded) {
            if (state.mensaje != null && state.eventos.isEmpty) {
              return Center(child: Text(state.mensaje!));
            }
            return Column(children: [
              if (state.resumen != null) _ParticipationSummary(resumen: state.resumen!),
              Expanded(child: _ParticipationTable(eventos: state.eventos)),
            ]);
          }
          if (state is ReportsFailure) {
            return Center(child: Text(state.error,
                style: const TextStyle(color: Colors.red)));
          }
          return const Center(child: Text('Seleccione los filtros y genere el reporte.'));
        },
      )),
    ]);
  }
}

class _ParticipationSummary extends StatelessWidget {
  final Map<String, dynamic> resumen;
  const _ParticipationSummary({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(children: [
        Text('Resumen General', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MiniStat('Eventos', '${resumen['total_eventos']}'),
          _MiniStat('Convocados', '${resumen['total_socios_convocados']}'),
          _MiniStat('Presentes', '${resumen['total_asistencia_fisica']}'),
          _MiniStat('Promedio', '${resumen['promedio_participacion']}%'),
        ]),
        const SizedBox(height: 4),
        Text('Mayor impacto: ${resumen['evento_mayor_impacto']}',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _ParticipationTable extends StatelessWidget {
  final List<dynamic> eventos;
  const _ParticipationTable({required this.eventos});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columns: const [
            DataColumn(label: Text('Evento')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Confirmados')),
            DataColumn(label: Text('Presentes')),
            DataColumn(label: Text('Tasa %')),
          ],
          rows: eventos.map((e) {
            final tasa = (e['tasa_participacion'] as num?)?.toDouble() ?? 0;
            return DataRow(cells: [
              DataCell(Text(e['nombre'] ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(Text(e['fecha'] ?? '')),
              DataCell(Text(e['tipo_evento'] ?? '')),
              DataCell(Text('${e['socios_confirmados']}')),
              DataCell(Text('${e['socios_presentes']}')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tasa >= 70 ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$tasa%',
                    style: TextStyle(
                      color: tasa >= 70 ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    )),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// TAB 2: HISTORIAL DE EVENTOS
// ════════════════════════════════════════════════════════
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoEvento = 'Todos';
  String _estado = 'Todos';

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => isStart ? _fechaInicio = d : _fechaFin = d);
  }

  void _generate() {
    if (_fechaInicio != null && _fechaFin != null && _fechaInicio!.isAfter(_fechaFin!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rango de fechas inválido. Verifique los valores ingresados.'),
        backgroundColor: Colors.red));
      return;
    }
    context.read<ReportsBloc>().add(ReportsGenerateHistory(
      fechaInicio: _fechaInicio != null ? DateFormat('yyyy-MM-dd').format(_fechaInicio!) : null,
      fechaFin: _fechaFin != null ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : null,
      tipoEvento: _tipoEvento,
      estado: _estado,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _FilterPanel(children: [
        Row(children: [
          Expanded(child: _DateButton(
            label: _fechaInicio == null ? 'Fecha inicio' : DateFormat('dd/MM/yy').format(_fechaInicio!),
            onTap: () => _pickDate(true),
          )),
          const SizedBox(width: 8),
          Expanded(child: _DateButton(
            label: _fechaFin == null ? 'Fecha fin' : DateFormat('dd/MM/yy').format(_fechaFin!),
            onTap: () => _pickDate(false),
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _tipoEvento,
            decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
            items: ['Todos', 'Social', 'Deportivo']
                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _tipoEvento = v!),
          )),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(
            value: _estado,
            decoration: const InputDecoration(labelText: 'Estado', isDense: true),
            items: ['Todos', 'Definido', 'Registrado', 'Difundido', 'Ejecutado', 'Cerrado']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _estado = v!),
          )),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Generar Reporte'),
            onPressed: _generate,
          )),
      ]),
      Expanded(child: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) return const Center(child: CircularProgressIndicator());
          if (state is ReportsHistoryLoaded) {
            if (state.mensaje != null && state.eventos.isEmpty) {
              return Center(child: Text(state.mensaje!));
            }
            return Column(children: [
              if (state.firmante != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: Text(
                    'CLUB DE SUBOFICIALES  ·  Firma: ${state.firmante}  ·  ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(child: _HistoryTable(eventos: state.eventos)),
            ]);
          }
          if (state is ReportsFailure) {
            return Center(child: Text(state.error, style: const TextStyle(color: Colors.red)));
          }
          return const Center(child: Text('Seleccione los filtros y genere el reporte.'));
        },
      )),
    ]);
  }
}

class _HistoryTable extends StatelessWidget {
  final List<dynamic> eventos;
  const _HistoryTable({required this.eventos});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('Código')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Lugar')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Presentes')),
            DataColumn(label: Text('Presupuesto')),
            DataColumn(label: Text('Gasto Total')),
          ],
          rows: eventos.map((e) => DataRow(cells: [
            DataCell(Text(e['codigo_evento'] ?? '-', style: const TextStyle(fontSize: 11))),
            DataCell(Text(e['nombre'] ?? '', style: const TextStyle(fontSize: 12))),
            DataCell(Text(e['tipo_evento'] ?? '')),
            DataCell(Text(e['fecha'] ?? '')),
            DataCell(Text(e['lugar'] ?? '', style: const TextStyle(fontSize: 11))),
            DataCell(Chip(
              label: Text(e['estado'] ?? '', style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
            )),
            DataCell(Text('${e['total_presentes'] ?? 0}')),
            DataCell(Text('\$${e['presupuesto_total'] ?? 0}')),
            DataCell(Text('\$${e['total_gastos'] ?? 0}',
              style: TextStyle(
                color: (e['total_gastos'] ?? 0) > (e['presupuesto_total'] ?? 0)
                    ? Colors.red : Colors.green,
              ))),
          ])).toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// TAB 3: LIQUIDACIONES
// ════════════════════════════════════════════════════════
class _LiquidationsTab extends StatefulWidget {
  const _LiquidationsTab();
  @override State<_LiquidationsTab> createState() => _LiquidationsTabState();
}

class _LiquidationsTabState extends State<_LiquidationsTab> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _estadoLiquidacion = 'Todas';

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => isStart ? _fechaInicio = d : _fechaFin = d);
  }

  void _generate() {
    context.read<ReportsBloc>().add(ReportsGenerateLiquidations(
      fechaInicio: _fechaInicio != null ? DateFormat('yyyy-MM-dd').format(_fechaInicio!) : null,
      fechaFin: _fechaFin != null ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : null,
      estadoLiquidacion: _estadoLiquidacion,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _FilterPanel(children: [
        Row(children: [
          Expanded(child: _DateButton(
            label: _fechaInicio == null ? 'Fecha inicio' : DateFormat('dd/MM/yy').format(_fechaInicio!),
            onTap: () => _pickDate(true),
          )),
          const SizedBox(width: 8),
          Expanded(child: _DateButton(
            label: _fechaFin == null ? 'Fecha fin' : DateFormat('dd/MM/yy').format(_fechaFin!),
            onTap: () => _pickDate(false),
          )),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _estadoLiquidacion,
          decoration: const InputDecoration(labelText: 'Estado liquidación', isDense: true),
          items: ['Todas', 'Cerrada', 'Pendiente']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _estadoLiquidacion = v!),
        ),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Generar Reporte'),
            onPressed: _generate,
          )),
      ]),
      Expanded(child: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) return const Center(child: CircularProgressIndicator());
          if (state is ReportsLiquidationsLoaded) {
            if (state.mensaje != null && state.liquidaciones.isEmpty) {
              return Center(child: Text(state.mensaje!));
            }
            return Column(children: [
              if (state.resumen != null) _LiquidationSummary(resumen: state.resumen!),
              Expanded(child: _LiquidationsList(liquidaciones: state.liquidaciones)),
            ]);
          }
          if (state is ReportsFailure) {
            return Center(child: Text(state.error, style: const TextStyle(color: Colors.red)));
          }
          return const Center(child: Text('Seleccione los filtros y genere el reporte.'));
        },
      )),
    ]);
  }
}

class _LiquidationSummary extends StatelessWidget {
  final Map<String, dynamic> resumen;
  const _LiquidationSummary({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final saldo = (resumen['saldo_general'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: saldo >= 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: saldo >= 0 ? Colors.green : Colors.red),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _MiniStat('Ingresos', '\$${resumen['total_ingresos']}', color: Colors.green),
        _MiniStat('Gastos', '\$${resumen['total_gastos']}', color: Colors.red),
        _MiniStat('Saldo', '\$${resumen['saldo_general']}',
            color: saldo >= 0 ? Colors.green : Colors.red),
        _MiniStat('Eventos', '${resumen['total_eventos']}'),
      ]),
    );
  }
}

class _LiquidationsList extends StatelessWidget {
  final List<dynamic> liquidaciones;
  const _LiquidationsList({required this.liquidaciones});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: liquidaciones.length,
      itemBuilder: (context, i) {
        final l = liquidaciones[i];
        final saldo = (l['saldo_final'] as num?)?.toDouble() ?? 0;
        final esCerrada = l['estado_liquidacion'] == 'Cerrada';
        final parcial = l['informacion_parcial'] == true;
        return Card(
          child: ExpansionTile(
            leading: Icon(
              esCerrada ? Icons.lock : Icons.lock_open,
              color: esCerrada ? Colors.green : Colors.orange,
            ),
            title: Text(l['nombre'] ?? ''),
            subtitle: Text('${l['fecha']} · ${l['tipo_evento']}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                '\$${saldo.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: saldo >= 0 ? Colors.green : Colors.red,
                ),
              ),
              Text(l['estado_liquidacion'] ?? '',
                  style: const TextStyle(fontSize: 10)),
            ]),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  if (parcial)
                    const Chip(
                      label: Text('Información parcial',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.orange,
                    ),
                  _LiqRow('Presupuesto', '\$${l['presupuesto_total'] ?? 0}'),
                  _LiqRow('Ingresos (aportes período)', '\$${(l['total_ingresos'] as num?)?.toStringAsFixed(2) ?? '0'}'),
                  _LiqRow('Total gastos', '\$${(l['total_gastos'] as num?)?.toStringAsFixed(2) ?? '0'}',
                      color: Colors.red),
                  const Divider(),
                  _LiqRow('Saldo final', '\$${saldo.toStringAsFixed(2)}',
                      bold: true, color: saldo >= 0 ? Colors.green : Colors.red),
                  _LiqRow('Asistentes reales', '${l['total_presentes'] ?? 0}'),
                  if (l['fecha_cierre'] != null)
                    _LiqRow('Fecha cierre', l['fecha_cierre'].toString().substring(0, 10)),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiqRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _LiqRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        )),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS
// ════════════════════════════════════════════════════════
class _FilterPanel extends StatelessWidget {
  final List<Widget> children;
  const _FilterPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade50,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(
        fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}