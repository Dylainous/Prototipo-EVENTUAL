import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/execute_event_bloc.dart';

class EventClosePage extends StatefulWidget {
  final Map<String, dynamic> evento;
  const EventClosePage({super.key, required this.evento});

  @override
  State<EventClosePage> createState() => _EventClosePageState();
}

class _EventClosePageState extends State<EventClosePage> {
  @override
  void initState() {
    super.initState();
    context.read<ExecuteEventBloc>()
        .add(ExecuteEventLoadSummary(widget.evento['id']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cerrar: ${widget.evento['nombre']}')),
      body: BlocConsumer<ExecuteEventBloc, ExecuteEventState>(
        listener: (context, state) {
          if (state is ExecuteEventCloseSuccess) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('Evento cerrado'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock, color: Colors.red, size: 56),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 8),
                  Text('Tasa de participación: ${state.tasaParticipacion}%',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          } else if (state is ExecuteEventFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is ExecuteEventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExecuteEventSummaryLoaded) {
            final r = state.resumen;
            final tasa = r['tasa_participacion'] ?? 0;
            final estaEnRojo =
                (r['monto_total_gastos'] ?? 0) > (r['presupuesto_total'] ?? 0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Resumen asistencia ─────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text('Resumen de Asistencia',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        _Row('Socios confirmados', '${r['total_confirmados']}'),
                        _Row('Presentes reales', '${r['total_presentes']}',
                            bold: true),
                        _Row('Tasa de participación', '$tasa%',
                            color: tasa >= 70 ? Colors.green : Colors.orange),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Resumen financiero ─────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text('Resumen Financiero',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        _Row('Presupuesto total',
                            '\$${r['presupuesto_total'] ?? 0}'),
                        _Row('Total gastos registrados',
                            '\$${r['monto_total_gastos'] ?? 0}',
                            color: estaEnRojo ? Colors.red : Colors.green),
                        _Row('N° de gastos', '${r['total_gastos_registrados']}'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Aviso irreversible ─────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El cierre del evento es irreversible. '
                          'Una vez cerrado, no podrá modificar la asistencia ni los datos operativos.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Cerrar Evento Definitivamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _confirmClose(context),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cerrar el evento?'),
        content: const Text(
            'Esta acción es irreversible. El evento quedará cerrado y habilitado para liquidación.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              context.read<ExecuteEventBloc>()
                  .add(ExecuteEventClose(widget.evento['id']));
            },
            child: const Text('Confirmar Cierre'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text(value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color)),
      ]),
    );
  }
}