// lib/features/members/presentation/pages/members_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/members_bloc.dart';
import '../../domain/entities/member_entity.dart';
import 'member_form_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  @override
  void initState() {
    super.initState();
    context.read<MembersBloc>()
      ..add(MembersLoadRequested())
      ..add(MembersLoadRolesRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Miembros'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<MembersBloc>(),
              child: const MemberFormPage(),
            ),
          ),
        ).then((_) => context.read<MembersBloc>().add(MembersLoadRequested())),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar Socio'),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: BlocConsumer<MembersBloc, MembersState>(
        listener: (context, state) {
          if (state is MembersOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          } else if (state is MembersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MembersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MembersLoaded) {
            if (state.members.isEmpty) {
              return const Center(child: Text('No hay socios registrados'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.members.length,
              itemBuilder: (ctx, i) =>
                  _MemberCard(member: state.members[i], roles: state.roles),
            );
          }
          if (state is MembersError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberEntity member;
  final List<RoleEntity> roles;
  const _MemberCard({required this.member, required this.roles});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isActivo
              ? const Color(0xFF1A237E)
              : Colors.grey,
          child: Text(
            member.nombres[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          member.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${member.rolNombre} • ${member.estado}\nCédula: ${member.cedula}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, value, member, roles),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modificar')),
            const PopupMenuItem(value: 'role', child: Text('Asignar Rol')),
            if (member.isActivo)
              const PopupMenuItem(
                value: 'deactivate',
                child: Text('Desactivar', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action,
      MemberEntity member, List<RoleEntity> roles) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<MembersBloc>(),
              child: MemberFormPage(member: member),
            ),
          ),
        ).then((_) => context.read<MembersBloc>().add(MembersLoadRequested()));
        break;
      case 'role':
        _showRoleDialog(context, member, roles);
        break;
      case 'deactivate':
        _showDeactivateDialog(context, member);
        break;
    }
  }

  void _showRoleDialog(
      BuildContext context, MemberEntity member, List<RoleEntity> roles) {
    int selectedRolId = member.rolId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Asignar Rol a ${member.nombres}'),
        content: StatefulBuilder(
          builder: (ctx2, setState) => DropdownButton<int>(
            value: selectedRolId,
            isExpanded: true,
            items: roles
                .map((r) =>
                    DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                .toList(),
            onChanged: (v) => setState(() => selectedRolId = v!),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<MembersBloc>()
                  .add(MemberAssignRoleRequested(member.id, selectedRolId));
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context, MemberEntity member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Socio'),
        content: Text(
            '¿Estás seguro de desactivar a ${member.nombreCompleto}? No podrá iniciar sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context
                  .read<MembersBloc>()
                  .add(MemberDeactivateRequested(member.id));
              Navigator.pop(ctx);
            },
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
