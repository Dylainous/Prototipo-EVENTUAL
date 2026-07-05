// lib/features/members/presentation/pages/member_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/members_bloc.dart';
import '../../domain/entities/member_entity.dart';

class MemberFormPage extends StatefulWidget {
  final MemberEntity? member; // null = crear, not null = editar
  const MemberFormPage({super.key, this.member});

  @override
  State<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends State<MemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apellidosCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionCtrl;
  int _selectedRolId = 1;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _cedulaCtrl = TextEditingController(text: m?.cedula ?? '');
    _nombresCtrl = TextEditingController(text: m?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: m?.apellidos ?? '');
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController(text: m?.telefono ?? '');
    _direccionCtrl = TextEditingController(text: m?.direccion ?? '');
    _selectedRolId = m?.rolId ?? 1;
  }

  @override
  void dispose() {
    for (final c in [
      _cedulaCtrl, _nombresCtrl, _apellidosCtrl,
      _emailCtrl, _passCtrl, _telefonoCtrl, _direccionCtrl
    ]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<MembersBloc>();
    if (_isEditing) {
      bloc.add(MemberUpdateRequested(widget.member!.id, {
        'nombres': _nombresCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
      }));
    } else {
      bloc.add(MemberCreateRequested({
        'cedula': _cedulaCtrl.text.trim(),
        'nombres': _nombresCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
        'telefono': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'rol_id': _selectedRolId,
      }));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modificar Socio' : 'Agregar Socio'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<MembersBloc, MembersState>(
        listener: (context, state) {
          if (state is MembersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(children: [
              if (!_isEditing) ...[
                _field(_cedulaCtrl, 'Cédula', Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v?.length != 10)
                        ? 'Cédula debe tener 10 dígitos'
                        : null),
                const SizedBox(height: 12),
                _field(_emailCtrl, 'Correo electrónico', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Email inválido' : null),
                const SizedBox(height: 12),
                _field(_passCtrl, 'Contraseña', Icons.lock_outline,
                    obscure: true,
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Mínimo 8 caracteres'
                        : null),
                const SizedBox(height: 12),
              ],
              _field(_nombresCtrl, 'Nombres', Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 12),
              _field(_apellidosCtrl, 'Apellidos', Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 12),
              _field(_telefonoCtrl, 'Teléfono (opcional)',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_direccionCtrl, 'Dirección (opcional)',
                  Icons.home_outlined,
                  maxLines: 2),
              if (!_isEditing) ...[
                const SizedBox(height: 12),
                BlocBuilder<MembersBloc, MembersState>(
                  builder: (ctx, state) {
                    final roles = state is MembersLoaded ? state.roles : [];
                    return DropdownButtonFormField<int>(
                      value: _selectedRolId,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: roles
                        .map((r) => DropdownMenuItem<int>(
                            value: r.id, child: Text(r.nombre)))
                        .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRolId = v ?? 1),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_isEditing ? 'Guardar Cambios' : 'Agregar Socio',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
