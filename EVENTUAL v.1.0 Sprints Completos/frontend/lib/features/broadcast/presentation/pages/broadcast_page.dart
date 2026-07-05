import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/broadcast_bloc.dart';

class BroadcastPage extends StatelessWidget {
  const BroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Difundir Evento')),
      body: BlocConsumer<BroadcastBloc, BroadcastState>(
        listener: (context, state) {
          if (state is BroadcastSuccess) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('¡Difusión exitosa!'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 56),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 8),
                  Text('Socios notificados: ${state.sociosNotificados}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<BroadcastBloc>().add(BroadcastLoadEvents());
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          } else if (state is BroadcastFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is BroadcastInitial) {
            context.read<BroadcastBloc>().add(BroadcastLoadEvents());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BroadcastLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BroadcastEventsLoaded) {
            if (state.eventos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay eventos en estado "Registrado" disponibles para difundir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.eventos.length,
              itemBuilder: (context, i) {
                final e = state.eventos[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.campaign)),
                    title: Text(e['nombre'] ?? ''),
                    subtitle: Text(
                        '${e['tipo_evento']} · ${e['fecha']} ${e['hora']}\n${e['lugar']}'),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () => context
                          .read<BroadcastBloc>()
                          .add(BroadcastLoadTemplate(e['id'])),
                      child: const Text('Difundir'),
                    ),
                  ),
                );
              },
            );
          }
          if (state is BroadcastTemplateLoaded) {
            return _BroadcastForm(
              plantilla: state.plantilla,
              evento: state.evento,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _BroadcastForm extends StatefulWidget {
  final String plantilla;
  final Map<String, dynamic> evento;

  const _BroadcastForm({required this.plantilla, required this.evento});

  @override
  State<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends State<_BroadcastForm> {
  late TextEditingController _mensajeCtrl;
  final List<String> _canalesSeleccionados = ['app'];
  bool _esInmediata = true;
  DateTime? _fechaProgramada;
  TimeOfDay? _horaProgramada;
  final Set<int> _recordatoriosSeleccionados = {15};

  @override
  void initState() {
    super.initState();
    _mensajeCtrl = TextEditingController(text: widget.plantilla);
  }

  Future<void> _pickFechaProgramada() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.parse(widget.evento['fecha']),
    );
    if (d != null) setState(() => _fechaProgramada = d);
  }

  Future<void> _pickHoraProgramada() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _horaProgramada = t);
  }

  void _submit() {
    if (_mensajeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debe definir el contenido del mensaje antes de continuar.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_canalesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debe seleccionar al menos un canal de difusión.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!_esInmediata && (_fechaProgramada == null || _horaProgramada == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La fecha y hora de envío no son válidas.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String? fechaEnvioStr;
    if (!_esInmediata && _fechaProgramada != null && _horaProgramada != null) {
      final dt = DateTime(
        _fechaProgramada!.year, _fechaProgramada!.month, _fechaProgramada!.day,
        _horaProgramada!.hour, _horaProgramada!.minute,
      );
      fechaEnvioStr = dt.toIso8601String();
    }

    context.read<BroadcastBloc>().add(BroadcastSubmitted(
      eventoId: widget.evento['id'],
      mensaje: _mensajeCtrl.text,
      canales: _canalesSeleccionados,
      esInmediata: _esInmediata,
      fechaEnvio: fechaEnvioStr,
      recordatorios: _recordatoriosSeleccionados.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info del evento ──────────────────────────
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.evento['nombre'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${widget.evento['fecha']} ${widget.evento['hora']} · ${widget.evento['lugar']}',
                    style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Mensaje ──────────────────────────────────
          Text('Contenido del mensaje',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _mensajeCtrl,
            maxLines: 12,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // ── Canales ──────────────────────────────────
          Text('Canales de difusión',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilterChip(
              label: const Text('App (Notificación interna)'),
              selected: _canalesSeleccionados.contains('app'),
              onSelected: (v) => setState(() =>
                v ? _canalesSeleccionados.add('app')
                  : _canalesSeleccionados.remove('app')),
            ),
            FilterChip(
              label: const Text('WhatsApp'),
              selected: _canalesSeleccionados.contains('whatsapp'),
              onSelected: (v) => setState(() =>
                v ? _canalesSeleccionados.add('whatsapp')
                  : _canalesSeleccionados.remove('whatsapp')),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Tipo de envío ─────────────────────────────
          Text('Tipo de envío', style: Theme.of(context).textTheme.titleSmall),
          RadioListTile<bool>(
            title: const Text('Inmediato'),
            value: true,
            groupValue: _esInmediata,
            onChanged: (v) => setState(() => _esInmediata = v!),
          ),
          RadioListTile<bool>(
            title: const Text('Programado'),
            value: false,
            groupValue: _esInmediata,
            onChanged: (v) => setState(() => _esInmediata = v!),
          ),
          if (!_esInmediata) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de envío'),
              subtitle: Text(_fechaProgramada == null
                  ? 'Seleccionar'
                  : DateFormat('dd/MM/yyyy').format(_fechaProgramada!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickFechaProgramada,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hora de envío'),
              subtitle: Text(_horaProgramada == null
                  ? 'Seleccionar'
                  : _horaProgramada!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: _pickHoraProgramada,
            ),
          ],
          const SizedBox(height: 16),

          // ── Recordatorios ─────────────────────────────
          Text('Recordatorios', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final dias in [15, 7, 1])
              FilterChip(
                label: Text('$dias día${dias > 1 ? 's' : ''} antes'),
                selected: _recordatoriosSeleccionados.contains(dias),
                onSelected: (v) => setState(() =>
                  v ? _recordatoriosSeleccionados.add(dias)
                    : _recordatoriosSeleccionados.remove(dias)),
              ),
          ]),
          const SizedBox(height: 24),

          // ── Botón confirmar ───────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Confirmar Difusión'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}