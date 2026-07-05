import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class ProvidersPage extends StatefulWidget {
  final String? eventoId;
  const ProvidersPage({super.key, this.eventoId});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _proveedores = [];
  bool _loading = true;
  String? _categoriaFiltro;

  static const _categorias = ['Alimentación','Sonido','Decoración','Transporte','Seguridad','Entretenimiento','Otros'];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);
    try {
      final q = _categoriaFiltro != null ? '?categoria=$_categoriaFiltro' : '';
      final resp = await _api.get('/providers$q');
      setState(() { _proveedores = resp['proveedores'] ?? []; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addCandidate(String proveedorId) async {
    if (widget.eventoId == null) return;
    try {
      await _api.post('/providers/candidates', {'evento_id': widget.eventoId, 'proveedor_id': proveedorId});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor marcado como candidato'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ','')), backgroundColor: Colors.red));
    }
  }

  void _openCreateForm() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProviderForm(api: _api, onSaved: _loadProviders));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add), label: const Text('Nuevo')),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            FilterChip(label: const Text('Todos'),
              selected: _categoriaFiltro == null,
              onSelected: (_) { setState(() => _categoriaFiltro = null); _loadProviders(); }),
            const SizedBox(width: 8),
            ..._categorias.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(label: Text(c),
                selected: _categoriaFiltro == c,
                onSelected: (_) { setState(() => _categoriaFiltro = c); _loadProviders(); }),
            )),
          ]),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _proveedores.isEmpty
            ? const Center(child: Text('No hay proveedores disponibles.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _proveedores.length,
                itemBuilder: (context, i) {
                  final p = _proveedores[i];
                  return Card(child: ListTile(
                    leading: const Icon(Icons.store),
                    title: Text(p['nombre'] ?? ''),
                    subtitle: Text('${p['categoria']} · ${p['ciudad'] ?? ''}'),
                    trailing: widget.eventoId != null
                      ? IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _addCandidate(p['id']),
                          tooltip: 'Marcar candidato')
                      : Text('⭐ ${p['calificacion'] ?? 0}'),
                    onTap: () => _showDetail(context, p),
                  ));
                }),
        ),
      ]),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> p) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(p['nombre'] ?? ''),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Categoría: ${p['categoria']}'),
        Text('Teléfono: ${p['telefono'] ?? '-'}'),
        Text('Email: ${p['email'] ?? '-'}'),
        Text('Dirección: ${p['direccion'] ?? '-'}'),
        Text('Ciudad: ${p['ciudad'] ?? '-'}'),
        if (p['servicios_ofrecidos'] != null) ...[
          const SizedBox(height: 8),
          Text('Servicios: ${p['servicios_ofrecidos']}'),
        ],
        Text('Calificación: ${p['calificacion'] ?? 0}/5'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    ));
  }
}

class _ProviderForm extends StatefulWidget {
  final ApiClient api;
  final VoidCallback onSaved;
  const _ProviderForm({required this.api, required this.onSaved});
  @override State<_ProviderForm> createState() => _ProviderFormState();
}

class _ProviderFormState extends State<_ProviderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _serviciosCtrl = TextEditingController();
  String _categoria = 'Alimentación';

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.api.post('/providers', {
        'nombre': _nombreCtrl.text, 'categoria': _categoria,
        'telefono': _telefonoCtrl.text, 'email': _emailCtrl.text,
        'direccion': _direccionCtrl.text, 'ciudad': _ciudadCtrl.text,
        'servicios_ofrecidos': _serviciosCtrl.text,
      });
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _formKey, child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Registrar Proveedor', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: _categoria,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: ['Alimentación','Sonido','Decoración','Transporte','Seguridad','Entretenimiento','Otros']
              .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _categoria = v!)),
          const SizedBox(height: 8),
          TextFormField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
          const SizedBox(height: 8),
          TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextFormField(controller: _ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad')),
          const SizedBox(height: 8),
          TextFormField(controller: _serviciosCtrl,
            decoration: const InputDecoration(labelText: 'Servicios ofrecidos'), maxLines: 2),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(onPressed: _submit, child: const Text('Guardar Proveedor'))),
        ],
      ))),
    );
  }
}