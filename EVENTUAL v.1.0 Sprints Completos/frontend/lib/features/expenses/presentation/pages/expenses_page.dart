import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/expenses_bloc.dart';

class ExpensesPage extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;

  const ExpensesPage({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpensesBloc>().add(ExpensesLoadRequested(widget.eventoId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gastos: ${widget.eventoNombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Registrar gasto',
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: BlocConsumer<ExpensesBloc, ExpensesState>(
        listener: (context, state) {
          if (state is ExpenseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (state.alertaPresupuesto != null) {
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.alertaPresupuesto!),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              });
            }
            context
                .read<ExpensesBloc>()
                .add(ExpensesLoadRequested(widget.eventoId));
          } else if (state is ExpenseFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ExpensesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpensesLoaded) {
            if (state.gastos.isEmpty) {
              return const Center(
                child: Text('No hay gastos registrados para este evento.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.gastos.length,
              itemBuilder: (context, i) {
                final g = state.gastos[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(g['descripcion'] ?? ''),
                    subtitle: Text(
                      'Categoría: ${g['categoria']}  |  Método: ${g['metodo_pago']}',
                    ),
                    trailing: Text(
                      '\$${(g['monto'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ExpensesBloc>(),
        child: _ExpenseForm(eventoId: widget.eventoId),
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final String eventoId;
  const _ExpenseForm({required this.eventoId});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();

  String _categoria = 'Alimentación';
  String _metodoPago = 'Efectivo';
  DateTime _fechaGasto = DateTime.now();

  static const _categorias = [
    'Alimentación',
    'Transporte',
    'Decoración',
    'Logística',
    'Entretenimiento',
    'Seguridad',
    'Otros',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaGasto,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaGasto = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ExpensesBloc>().add(ExpenseSubmitted(
          eventoId: widget.eventoId,
          categoria: _categoria,
          monto: double.parse(_montoCtrl.text),
          fechaGasto: DateFormat('yyyy-MM-dd').format(_fechaGasto),
          metodoPago: _metodoPago,
          descripcion: _descripcionCtrl.text,
          responsable: _responsableCtrl.text,
          proveedor: _proveedorCtrl.text.isEmpty ? null : _proveedorCtrl.text,
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
              Text('Registrar Gasto',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Monto pagado (\$)'),
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
                title: const Text('Fecha del gasto'),
                subtitle:
                    Text(DateFormat('dd/MM/yyyy').format(_fechaGasto)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
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
                  DropdownMenuItem(
                      value: 'Tarjeta', child: Text('Tarjeta')),
                ],
                onChanged: (v) => setState(() => _metodoPago = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descripción del gasto'),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingrese la descripción' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _responsableCtrl,
                decoration:
                    const InputDecoration(labelText: 'Responsable del gasto'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingrese el responsable' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proveedorCtrl,
                decoration: const InputDecoration(
                    labelText: 'Proveedor (opcional)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Guardar Gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
