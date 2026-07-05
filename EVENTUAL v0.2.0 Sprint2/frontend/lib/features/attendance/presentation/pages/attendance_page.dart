import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/attendance_bloc.dart';

class AttendancePage extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;
  final String eventoFecha;

  const AttendancePage({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
    required this.eventoFecha,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool? _asiste;
  int _numAcompanantes = 0;
  final List<Map<String, TextEditingController>> _acompanantesControllers = [];
  final _comentariosCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(AttendanceLoadRequested(widget.eventoId));
  }

  void _updateAcompanantes(int count) {
    setState(() {
      _numAcompanantes = count;
      _acompanantesControllers.clear();
      for (int i = 0; i < count; i++) {
        _acompanantesControllers.add({
          'nombre': TextEditingController(),
          'edad': TextEditingController(),
          'relacion': TextEditingController(),
        });
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_asiste == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una opción de asistencia')),
      );
      return;
    }

    final acompanantes = _acompanantesControllers.map((c) => {
      'nombre': c['nombre']!.text,
      'edad': int.tryParse(c['edad']!.text) ?? 0,
      'relacion': c['relacion']!.text,
    }).toList();

    context.read<AttendanceBloc>().add(AttendanceSubmitted(
      eventoId: widget.eventoId,
      asiste: _asiste!,
      numAcompanantes: _numAcompanantes,
      acompanantes: acompanantes,
      comentarios: _comentariosCtrl.text.isEmpty ? null : _comentariosCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirmar Asistencia')),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else if (state is AttendanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoading) return const Center(child: CircularProgressIndicator());

          if (state is AttendanceLoaded && state.confirmacion != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('Ya has confirmado tu asistencia para este evento.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Asiste: ${state.confirmacion!['asiste'] == true ? 'Sí' : 'No'}'),
                  Text('Acompañantes: ${state.confirmacion!['num_acompanantes']}'),
                ]),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.eventoNombre, style: Theme.of(context).textTheme.titleLarge),
                      Text('Fecha: ${widget.eventoFecha}'),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('¿Asistirá al evento?', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<bool>(
                  title: const Text('Sí asistiré'),
                  value: true,
                  groupValue: _asiste,
                  onChanged: (v) => setState(() { _asiste = v; if (v == false) _updateAcompanantes(0); }),
                ),
                RadioListTile<bool>(
                  title: const Text('No asistiré'),
                  value: false,
                  groupValue: _asiste,
                  onChanged: (v) => setState(() { _asiste = v; _updateAcompanantes(0); }),
                ),
                if (_asiste == true) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Número de acompañantes (0–5)'),
                    value: _numAcompanantes,
                    items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (v) => _updateAcompanantes(v ?? 0),
                  ),
                  ..._acompanantesControllers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final c = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(top: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Text('Acompañante ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: c['nombre'],
                            decoration: const InputDecoration(labelText: 'Nombre completo'),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: c['edad'],
                            decoration: const InputDecoration(labelText: 'Edad'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: c['relacion'],
                            decoration: const InputDecoration(labelText: 'Relación (familiar, amigo, etc.)'),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ]),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _comentariosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios adicionales (opcional)',
                    hintText: 'Alergias, necesidades especiales...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state is AttendanceLoading ? null : _submit,
                  child: const Text('Enviar Confirmación'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}