import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/execute_event_bloc.dart';
import 'attendance_list_page.dart';
import 'event_close_page.dart';

class ExecuteEventPage extends StatelessWidget {
  const ExecuteEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejecutar Evento')),
      body: BlocConsumer<ExecuteEventBloc, ExecuteEventState>(
        listener: (context, state) {
          if (state is ExecuteEventFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is ExecuteEventInitial) {
            context.read<ExecuteEventBloc>().add(ExecuteEventLoadActive());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExecuteEventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExecuteEventActiveLoaded) {
            if (state.eventos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay eventos activos para ejecutar.\nLos eventos deben estar en estado "Difundido" o "Ejecutado".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ]),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.eventos.length,
              itemBuilder: (context, i) {
                final ev = state.eventos[i];
                final esEjecutado = ev['estado'] == 'Ejecutado';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Chip(
                            label: Text(ev['estado'] ?? ''),
                            backgroundColor: esEjecutado
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                          ),
                          const SizedBox(width: 8),
                          if (ev['codigo_evento'] != null)
                            Text(ev['codigo_evento'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                        ]),
                        const SizedBox(height: 8),
                        Text(ev['nombre'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${ev['fecha']} ${ev['hora']} · ${ev['lugar']}'),
                        if (esEjecutado)
                          Text(
                            'Presentes: ${ev['total_presentes'] ?? 0}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.how_to_reg),
                              label: const Text('Registrar Asistencia'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<ExecuteEventBloc>(),
                                    child: AttendanceListPage(evento: ev),
                                  ),
                                ),
                              ).then((_) => context
                                  .read<ExecuteEventBloc>()
                                  .add(ExecuteEventLoadActive())),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock),
                              label: const Text('Cerrar Evento'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: esEjecutado
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: context
                                                .read<ExecuteEventBloc>(),
                                            child: EventClosePage(evento: ev),
                                          ),
                                        ),
                                      ).then((_) => context
                                          .read<ExecuteEventBloc>()
                                          .add(ExecuteEventLoadActive()))
                                  : null,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}