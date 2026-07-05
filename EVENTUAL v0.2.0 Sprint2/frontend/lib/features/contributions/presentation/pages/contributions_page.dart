import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/contributions_bloc.dart';

class ContributionsPage extends StatelessWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Aportes Económicos')),
      body: BlocConsumer<ContributionsBloc, ContributionsState>(
        listener: (context, state) {
          if (state is ContributionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Recargar lista de pendientes
            context
                .read<ContributionsBloc>()
                .add(ContributionsPendingRequested());
          } else if (state is ContributionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ContributionsInitial) {
            context
                .read<ContributionsBloc>()
                .add(ContributionsPendingRequested());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ContributionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ContributionsLoaded) {
            return _PendingList(
              pendientes: state.pendientes,
              cuotaEstandar: state.cuotaEstandar,
              periodo: state.periodo,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final List<dynamic> pendientes;
  final double cuotaEstandar;
  final String periodo;

  const _PendingList({
    required this.pendientes,
    required this.cuotaEstandar,
    required this.periodo,
  });

  @override
  Widget build(BuildContext context) {
    if (pendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('Todos los socios han pagado el período $periodo',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.blue.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Período: $periodo  |  Cuota estándar: \$${cuotaEstandar.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pendientes.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, i) {
              final socio = pendientes[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                      '${socio['nombres']} ${socio['apellidos']}'),
                  subtitle: Text('Cédula: ${socio['cedula']}'),
                  trailing: ElevatedButton(
                    onPressed: () => _openForm(context, socio),
                    child: const Text('Registrar'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openForm(BuildContext context, Map<String, dynamic> socio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ContributionsBloc>(),
        child: _ContributionForm(
          socio: socio,
          cuotaEstandar: cuotaEstandar,
        ),
      ),
    );
  }
}

class _ContributionForm extends StatefulWidget {
  final Map<String, dynamic> socio;
  final double cuotaEstandar;

  const _ContributionForm({
    required this.socio,
    required this.cuotaEstandar,
  });

  @override
  State<_ContributionForm> createState() => _ContributionFormState();
}

class _ContributionFormState extends State<_ContributionForm> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();

  String _metodoPago = 'Efectivo';
  String _estado = 'Validado';
  DateTime _fechaPago = DateTime.now();

  @override
  void initState() {
    super.initState();
    _montoCtrl.text = widget.cuotaEstandar.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaPago = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ContributionsBloc>().add(ContributionSubmitted(
          socioId: widget.socio['id'],
          metodoPago: _metodoPago,
          monto: double.parse(_montoCtrl.text),
          fechaPago: DateFormat('yyyy-MM-dd').format(_fechaPago),
          estado: _estado,
          observaciones: _observacionesCtrl.text.isEmpty
              ? null
              : _observacionesCtrl.text,
          comprobante: _comprobanteCtrl.text.isEmpty
              ? null
              : _comprobanteCtrl.text,
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registrar aporte de ${widget.socio['nombres']} ${widget.socio['apellidos']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _metodoPago,
                decoration:
                    const InputDecoration(labelText: 'Método de pago'),
                items: const [
                  DropdownMenuItem(
                      value: 'Efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(
                      value: 'Transferencia',
                      child: Text('Transferencia')),
                ],
                onChanged: (v) => setState(() => _metodoPago = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Monto recibido (\$)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el monto';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de pago'),
                subtitle:
                    Text(DateFormat('dd/MM/yyyy').format(_fechaPago)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              if (_metodoPago == 'Transferencia') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comprobanteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Número de comprobante'),
                  validator: (v) => (_metodoPago == 'Transferencia' &&
                          (v == null || v.isEmpty))
                      ? 'Ingrese el número de comprobante'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Acción'),
                items: const [
                  DropdownMenuItem(
                      value: 'Validado', child: Text('Aprobar')),
                  DropdownMenuItem(
                      value: 'Rechazado', child: Text('Rechazar')),
                ],
                onChanged: (v) => setState(() => _estado = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Guardar Aporte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
