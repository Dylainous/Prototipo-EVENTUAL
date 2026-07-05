// lib/features/proposals/presentation/pages/propose_event_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/proposals_bloc.dart';

class ProposeEventPage extends StatefulWidget {
  const ProposeEventPage({super.key});

  @override
  State<ProposeEventPage> createState() => _ProposeEventPageState();
}

class _ProposeEventPageState extends State<ProposeEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _tipoEvento = 'Social';
  final _descripcionCtrl = TextEditingController();
  final _justificacionCtrl = TextEditingController();
  DateTime? _fechaSugerida;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _justificacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fechaSugerida = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaSugerida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una fecha sugerida')),
      );
      return;
    }
    context.read<ProposalsBloc>().add(ProposalSubmitRequested(
          tipoEvento: _tipoEvento,
          descripcion: _descripcionCtrl.text.trim(),
          fechaSugerida:
              DateFormat('yyyy-MM-dd').format(_fechaSugerida!),
          justificacion: _justificacionCtrl.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proponer Evento'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<ProposalsBloc, ProposalsState>(
        listener: (context, state) {
          if (state is ProposalSubmitSuccess) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('¡Propuesta Enviada!'),
                ]),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Su propuesta ha sido registrada exitosamente. Recibirá notificación cuando sea evaluada.'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.confirmation_number,
                            color: Color(0xFF1A237E)),
                        const SizedBox(width: 8),
                        Text(
                          'N° ${state.numeroSeguimiento}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // cerrar dialog
                      Navigator.pop(context); // volver a home
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          } else if (state is ProposalsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completa el formulario con los detalles de tu propuesta',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Tipo de evento
                const Text('Tipo de Evento',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Social',
                      icon: Icons.people,
                      selected: _tipoEvento == 'Social',
                      color: Colors.blue.shade700,
                      onTap: () => setState(() => _tipoEvento = 'Social'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: 'Deportivo',
                      icon: Icons.sports_soccer,
                      selected: _tipoEvento == 'Deportivo',
                      color: Colors.green.shade700,
                      onTap: () => setState(() => _tipoEvento = 'Deportivo'),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Descripción
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del evento *',
                    hintText: 'Mínimo 50 caracteres...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 50) {
                      return 'La descripción debe tener al menos 50 caracteres. Actual: ${v?.trim().length ?? 0}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fecha sugerida
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF1A237E)),
                      const SizedBox(width: 12),
                      Text(
                        _fechaSugerida == null
                            ? 'Seleccionar fecha sugerida *'
                            : DateFormat('EEEE d MMMM yyyy', 'es')
                                .format(_fechaSugerida!),
                        style: TextStyle(
                          color: _fechaSugerida == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Justificación
                TextFormField(
                  controller: _justificacionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Justificación *',
                    hintText: '¿Por qué sería beneficioso este evento?',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 28),

                // Botón enviar
                BlocBuilder<ProposalsBloc, ProposalsState>(
                  builder: (ctx, state) {
                    if (state is ProposalsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar Propuesta',
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]),
      ),
    );
  }
}
