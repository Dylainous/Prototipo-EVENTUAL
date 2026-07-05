import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/plan_event_bloc.dart';
import 'providers_page.dart';

class PlanEventPage extends StatelessWidget {
  const PlanEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Proveedores',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProvidersPage())),
          ),
        ],
      ),
      body: BlocConsumer<PlanEventBloc, PlanEventState>(
        listener: (context, state) {
          if (state is PlanEventSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            context.read<PlanEventBloc>().add(PlanEventLoadProposals());
          } else if (state is PlanEventFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is PlanEventInitial) {
            context.read<PlanEventBloc>().add(PlanEventLoadProposals());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlanEventLoading) return const Center(child: CircularProgressIndicator());
          if (state is PlanEventProposalsLoaded) {
            if (state.propuestas.isEmpty) {
              return const Center(child: Text('No hay propuestas pendientes de revisión.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.propuestas.length,
              itemBuilder: (context, i) {
                final p = state.propuestas[i];
                final socio = p['profiles'];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Chip(label: Text(p['tipo_evento'] ?? ''),
                          backgroundColor: p['tipo_evento'] == 'Social'
                            ? Colors.blue.shade100 : Colors.green.shade100),
                        const SizedBox(width: 8),
                        Text('N° ${p['numero_seguimiento'] ?? ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 8),
                      Text(p['descripcion'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Fecha sugerida: ${p['fecha_sugerida'] ?? '-'}',
                        style: const TextStyle(fontSize: 12)),
                      Text('Justificación: ${p['justificacion'] ?? '-'}',
                        style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (socio != null)
                        Text('Propuesto por: ${socio['nombres']} ${socio['apellidos']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                            onPressed: () => _confirmReject(context, p),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Aprobar y Programar'),
                            onPressed: () => _openScheduleForm(context, p),
                          ),
                        ),
                      ]),
                    ]),
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

  void _confirmReject(BuildContext context, Map<String, dynamic> p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Rechazar propuesta'),
      content: const Text('¿Está seguro que desea rechazar esta propuesta?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context);
            context.read<PlanEventBloc>().add(PlanEventReject(p['id']));
          },
          child: const Text('Rechazar'),
        ),
      ],
    ));
  }

  void _openScheduleForm(BuildContext context, Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<PlanEventBloc>(),
        child: _ScheduleForm(propuesta: p),
      ),
    );
  }
}

class _ScheduleForm extends StatefulWidget {
  final Map<String, dynamic> propuesta;
  const _ScheduleForm({required this.propuesta});
  @override State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _lugarCtrl = TextEditingController();
  final _presupuestoCtrl = TextEditingController();
  final _cupoCtrl = TextEditingController();
  DateTime? _fecha;
  TimeOfDay? _hora;

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _hora = t);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null || _hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione fecha y hora del evento')));
      return;
    }
    final horaStr = '${_hora!.hour.toString().padLeft(2,'0')}:${_hora!.minute.toString().padLeft(2,'0')}';
    context.read<PlanEventBloc>().add(PlanEventApprove(
      propuestaId: widget.propuesta['id'],
      fecha: DateFormat('yyyy-MM-dd').format(_fecha!),
      hora: horaStr,
      lugar: _lugarCtrl.text,
      presupuesto: _presupuestoCtrl.text.isEmpty ? null : double.tryParse(_presupuestoCtrl.text),
      cupoMaximo: _cupoCtrl.text.isEmpty ? null : int.tryParse(_cupoCtrl.text),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Programar Evento', style: Theme.of(context).textTheme.titleMedium),
          Text(widget.propuesta['descripcion'] ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          ListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Fecha definitiva'),
            subtitle: Text(_fecha == null ? 'Seleccionar' : DateFormat('dd/MM/yyyy').format(_fecha!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate),
          ListTile(contentPadding: EdgeInsets.zero,
            title: const Text('Hora definitiva'),
            subtitle: Text(_hora == null ? 'Seleccionar' : _hora!.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime),
          const SizedBox(height: 8),
          TextFormField(controller: _lugarCtrl,
            decoration: const InputDecoration(labelText: 'Lugar / Ubicación'),
            validator: (v) => (v == null || v.isEmpty) ? 'Ingrese el lugar' : null),
          const SizedBox(height: 8),
          TextFormField(controller: _presupuestoCtrl,
            decoration: const InputDecoration(labelText: 'Presupuesto total \$ (opcional)'),
            keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextFormField(controller: _cupoCtrl,
            decoration: const InputDecoration(labelText: 'Cupo máximo (opcional)'),
            keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: _submit, child: const Text('Confirmar Programación'))),
        ],
      ))),
    );
  }
}