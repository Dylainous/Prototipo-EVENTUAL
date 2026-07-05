import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import 'providers_page.dart';

class QuotationsPage extends StatefulWidget {
  final String eventoId;
  final String eventoNombre;

  const QuotationsPage({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage>
    with SingleTickerProviderStateMixin {
  final _api = sl<ApiClient>();
  late TabController _tabController;

  List<dynamic> _cotizaciones = [];
  Map<String, dynamic>? _evaluacion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.get('/quotations/${widget.eventoId}');
      setState(() {
        _cotizaciones = resp['cotizaciones'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadEvaluation() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.get('/quotations/${widget.eventoId}/evaluate');
      setState(() {
        _evaluacion = resp;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _togglePreferred(String id, bool actual) async {
    try {
      await _api.patch('/quotations/$id/preferred',
          body: {'es_preferida': !actual});
      _loadQuotations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QuotationForm(
        api: _api,
        eventoId: widget.eventoId,
        onSaved: _loadQuotations,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cotizaciones: ${widget.eventoNombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Ver Proveedores',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProvidersPage(eventoId: widget.eventoId),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            if (i == 1) _loadEvaluation();
          },
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Cotizaciones'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Evaluar Costos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cotización'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQuotationsList(),
                _buildEvaluation(),
              ],
            ),
    );
  }

  Widget _buildQuotationsList() {
    if (_cotizaciones.isEmpty) {
      return const Center(
          child: Text('No hay cotizaciones registradas para este evento.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cotizaciones.length,
      itemBuilder: (context, i) {
        final c = _cotizaciones[i];
        final proveedor = c['proveedores'];
        final esPreferida = c['es_preferida'] == true;
        return Card(
          color: esPreferida ? Colors.amber.shade50 : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  esPreferida ? Colors.amber : Colors.grey.shade200,
              child: Icon(
                esPreferida ? Icons.star : Icons.star_border,
                color: esPreferida ? Colors.white : Colors.grey,
              ),
            ),
            title: Text(proveedor?['nombre'] ?? 'Proveedor'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c['tipo_servicio']} · ${c['moneda']} ${c['monto']}'),
                Text('Válida hasta: ${c['fecha_validez'] ?? '-'}',
                    style: const TextStyle(fontSize: 11)),
                if (c['costo_por_persona'] != null)
                  Text(
                      'Costo/persona: \$${c['costo_por_persona']}',
                      style: const TextStyle(fontSize: 11)),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                esPreferida ? Icons.star : Icons.star_border,
                color: esPreferida ? Colors.amber : Colors.grey,
              ),
              tooltip: esPreferida ? 'Quitar preferida' : 'Marcar preferida',
              onPressed: () => _togglePreferred(c['id'], esPreferida),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvaluation() {
    if (_evaluacion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_evaluacion!.containsKey('mensaje')) {
      return Center(child: Text(_evaluacion!['mensaje']));
    }

    final subtotales =
        (_evaluacion!['subtotales'] as Map<String, dynamic>?) ?? {};
    final costoTotal =
        (_evaluacion!['costo_total'] as num?)?.toDouble() ?? 0;
    final presupuesto =
        (_evaluacion!['presupuesto_total'] as num?)?.toDouble() ?? 0;
    final diferencia =
        (_evaluacion!['diferencia'] as num?)?.toDouble() ?? 0;
    final semaforo = _evaluacion!['semaforo'] ?? 'verde';
    final estaEnRojo = semaforo == 'rojo';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Semáforo presupuestario ─────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: estaEnRojo ? Colors.red.shade50 : Colors.green.shade50,
              border: Border.all(
                  color: estaEnRojo ? Colors.red : Colors.green),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                estaEnRojo ? Icons.warning_amber : Icons.check_circle,
                color: estaEnRojo ? Colors.red : Colors.green,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estaEnRojo
                            ? 'Presupuesto excedido'
                            : 'Dentro del presupuesto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: estaEnRojo ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                          'Diferencia: \$${diferencia.toStringAsFixed(2)}'),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Resumen financiero ──────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _SummaryRow('Presupuesto total',
                    '\$${presupuesto.toStringAsFixed(2)}'),
                _SummaryRow('Costo total estimado',
                    '\$${costoTotal.toStringAsFixed(2)}',
                    bold: true),
                const Divider(),
                _SummaryRow(
                  'Diferencia',
                  '\$${diferencia.toStringAsFixed(2)}',
                  color: estaEnRojo ? Colors.red : Colors.green,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Subtotales por categoría ────────────────────
          Text('Subtotales por categoría',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...subtotales.entries.map((e) => Card(
                child: ListTile(
                  title: Text(e.key),
                  trailing: Text(
                    '\$${(e.value as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _QuotationForm extends StatefulWidget {
  final ApiClient api;
  final String eventoId;
  final VoidCallback onSaved;

  const _QuotationForm({
    required this.api,
    required this.eventoId,
    required this.onSaved,
  });

  @override
  State<_QuotationForm> createState() => _QuotationFormState();
}

class _QuotationFormState extends State<_QuotationForm> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  String _tipoServicio = 'Alimentación';
  String _moneda = 'USD';
  DateTime? _fechaValidez;
  List<dynamic> _proveedores = [];
  String? _proveedorSeleccionado;
  bool _loadingProviders = true;

  static const _tiposServicio = [
    'Alimentación', 'Sonido', 'Decoración',
    'Transporte', 'Seguridad', 'Entretenimiento', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final resp = await widget.api.get('/providers');
      setState(() {
        _proveedores = resp['proveedores'] ?? [];
        _loadingProviders = false;
      });
    } catch (_) {
      setState(() => _loadingProviders = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _fechaValidez = d);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proveedorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione un proveedor')));
      return;
    }
    if (_fechaValidez == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione la fecha de validez')));
      return;
    }
    try {
      await widget.api.post('/quotations', {
        'evento_id': widget.eventoId,
        'proveedor_id': _proveedorSeleccionado,
        'tipo_servicio': _tipoServicio,
        'descripcion': _descripcionCtrl.text,
        'monto': double.parse(_montoCtrl.text),
        'moneda': _moneda,
        'fecha_validez':
            DateFormat('yyyy-MM-dd').format(_fechaValidez!),
        'observaciones': _observacionesCtrl.text.isEmpty
            ? null
            : _observacionesCtrl.text,
      });
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar Cotización',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _loadingProviders
                  ? const Center(child: CircularProgressIndicator())
                  : _proveedores.isEmpty
                      ? const Text('No hay proveedores. Regístrelos primero.')
                      : DropdownButtonFormField<String>(
                          value: _proveedorSeleccionado,
                          decoration:
                              const InputDecoration(labelText: 'Proveedor *'),
                          items: _proveedores
                              .map((p) => DropdownMenuItem<String>(
                                  value: p['id'],
                                  child: Text(p['nombre'])))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _proveedorSeleccionado = v),
                        ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoServicio,
                decoration:
                    const InputDecoration(labelText: 'Tipo de servicio'),
                items: _tiposServicio
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoServicio = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionCtrl,
                decoration:
                    const InputDecoration(labelText: 'Descripción *'),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(labelText: 'Monto *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0)
                    return 'El monto debe ser un valor numérico positivo.';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _moneda,
                decoration: const InputDecoration(labelText: 'Moneda'),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                ],
                onChanged: (v) => setState(() => _moneda = v!),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de validez *'),
                subtitle: Text(_fechaValidez == null
                    ? 'Seleccionar'
                    : DateFormat('dd/MM/yyyy').format(_fechaValidez!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _observacionesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Guardar Cotización')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}