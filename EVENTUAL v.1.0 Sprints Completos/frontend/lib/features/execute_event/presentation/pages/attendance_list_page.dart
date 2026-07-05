import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/execute_event_bloc.dart';

class AttendanceListPage extends StatelessWidget {
  final Map<String, dynamic> evento;
  const AttendanceListPage({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia: ${evento['nombre']}'),
      ),
      body: BlocConsumer<ExecuteEventBloc, ExecuteEventState>(
        listener: (context, state) {
          if (state is ExecuteEventAttendanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${state.message} · Total presentes: ${state.totalPresentes}'),
              backgroundColor: Colors.green,
            ));
            context.read<ExecuteEventBloc>()
                .add(ExecuteEventLoadList(state.eventoId));
          } else if (state is ExecuteEventFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is ExecuteEventInitial ||
              (state is ExecuteEventLoading)) {
            context.read<ExecuteEventBloc>()
                .add(ExecuteEventLoadList(evento['id']));
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExecuteEventLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExecuteEventListLoaded) {
            return _AttendanceListView(
              eventoId: evento['id'],
              confirmados: state.confirmados,
              noConfirmados: state.noConfirmados,
              totalPresentes: state.totalPresentes,
              totalConfirmados: state.totalConfirmados,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _AttendanceListView extends StatefulWidget {
  final String eventoId;
  final List<dynamic> confirmados;
  final List<dynamic> noConfirmados;
  final int totalPresentes;
  final int totalConfirmados;

  const _AttendanceListView({
    required this.eventoId,
    required this.confirmados,
    required this.noConfirmados,
    required this.totalPresentes,
    required this.totalConfirmados,
  });

  @override
  State<_AttendanceListView> createState() => _AttendanceListViewState();
}

class _AttendanceListViewState extends State<_AttendanceListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _registerAttendance(Map<String, dynamic> socio) {
    if (socio['presente'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Asistencia ya registrada para este participante'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _AttendanceDialog(
        socio: socio,
        eventoId: widget.eventoId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasa = widget.totalConfirmados > 0
        ? (widget.totalPresentes / widget.totalConfirmados * 100)
            .toStringAsFixed(1)
        : '0.0';

    return Column(children: [
      // ── Contador en tiempo real ───────────────────────
      Container(
        color: Colors.green.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatChip('Confirmados', '${widget.totalConfirmados}', Colors.blue),
            _StatChip('Presentes', '${widget.totalPresentes}', Colors.green),
            _StatChip('Tasa', '$tasa%', Colors.purple),
          ],
        ),
      ),
      TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Confirmados (${widget.confirmados.length})'),
          Tab(text: 'Sin confirmar (${widget.noConfirmados.length})'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(widget.confirmados),
            _buildList(widget.noConfirmados),
          ],
        ),
      ),
    ]);
  }

  Widget _buildList(List<dynamic> lista) {
    if (lista.isEmpty) {
      return const Center(child: Text('No hay socios en esta categoría.'));
    }
    return ListView.builder(
      itemCount: lista.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, i) {
        final s = lista[i];
        final presente = s['presente'] == true;
        return Card(
          color: presente ? Colors.green.shade50 : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: presente ? Colors.green : Colors.grey.shade200,
              child: Icon(
                presente ? Icons.check : Icons.person,
                color: presente ? Colors.white : Colors.grey,
              ),
            ),
            title: Text('${s['nombres']} ${s['apellidos']}'),
            subtitle: Text('Cédula: ${s['cedula']}'),
            trailing: presente
                ? const Chip(
                    label: Text('Presente',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: Colors.green,
                  )
                : ElevatedButton(
                    onPressed: () => _registerAttendance(s),
                    child: const Text('Marcar'),
                  ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

class _AttendanceDialog extends StatefulWidget {
  final Map<String, dynamic> socio;
  final String eventoId;
  const _AttendanceDialog({required this.socio, required this.eventoId});

  @override
  State<_AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<_AttendanceDialog> {
  int _acompanantes = 0;
  final _obsCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          'Registrar asistencia\n${widget.socio['nombres']} ${widget.socio['apellidos']}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          value: _acompanantes,
          decoration: const InputDecoration(labelText: 'Acompañantes presentes'),
          items: List.generate(
              6, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
          onChanged: (v) => setState(() => _acompanantes = v ?? 0),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _obsCtrl,
          decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<ExecuteEventBloc>().add(
              ExecuteEventRegisterAttendance(
                eventoId: widget.eventoId,
                socioId: widget.socio['socio_id'],
                numAcompanantes: _acompanantes,
                observaciones: _obsCtrl.text.isEmpty ? null : _obsCtrl.text,
              ),
            );
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}