import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/event_registration_bloc.dart';

class EventRegistrationPage extends StatelessWidget {
  final Map<String, dynamic> evento;

  const EventRegistrationPage({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Evento')),
      body: BlocConsumer<EventRegistrationBloc, EventRegistrationState>(
        listener: (context, state) {
          if (state is EventRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${state.message}  |  Código: ${state.codigoEvento}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.pop(context, true); // true = recargar la lista
          } else if (state is EventRegistrationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is EventRegistrationLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Resumen del evento ────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen del Evento',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        _InfoRow('Nombre', evento['nombre'] ?? '-'),
                        _InfoRow('Tipo', evento['tipo_evento'] ?? '-'),
                        _InfoRow('Fecha', evento['fecha'] ?? '-'),
                        _InfoRow('Hora', evento['hora'] ?? '-'),
                        _InfoRow('Lugar', evento['lugar'] ?? '-'),
                        _InfoRow('Estado actual', evento['estado'] ?? '-'),
                        if (evento['descripcion'] != null)
                          _InfoRow('Descripción', evento['descripcion']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Aviso de estado requerido ─────────────
                if (evento['estado'] != 'Definido')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este evento no está en estado "Definido". '
                          'Solo los eventos definidos pueden ser registrados.',
                          style:
                              TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ]),
                  ),

                if (evento['estado'] == 'Definido') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Al registrar el evento se generará un código único '
                          '(EVT-YYYY-NNN) y el estado cambiará a "Registrado". '
                          'Una vez registrado, el evento podrá ser difundido.',
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              _showConfirmDialog(context);
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                          isLoading ? 'Registrando...' : 'Registrar Evento'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar registro'),
        content: Text(
          '¿Está seguro que desea registrar el evento "${evento['nombre']}"?\n\n'
          'Esta acción generará un código único y cambiará el estado a "Registrado".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<EventRegistrationBloc>()
                  .add(EventRegistrationRequested(evento['id']));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
