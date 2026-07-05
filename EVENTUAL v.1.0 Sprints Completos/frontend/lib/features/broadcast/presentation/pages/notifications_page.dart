import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _notificaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.get('/broadcast/notifications');
      setState(() {
        _notificaciones = resp['notificaciones'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _api.patch('/broadcast/notifications/$id/read');
      _loadNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas =
        _notificaciones.where((n) => n['leida'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones${noLeidas > 0 ? ' ($noLeidas)' : ''}'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotifications,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? const Center(child: Text('No tienes notificaciones.'))
              : ListView.builder(
                  itemCount: _notificaciones.length,
                  itemBuilder: (context, i) {
                    final n = _notificaciones[i];
                    final leida = n['leida'] == true;
                    final evento = n['eventos'];
                    return ListTile(
                      tileColor: leida ? null : Colors.blue.shade50,
                      leading: CircleAvatar(
                        backgroundColor:
                            leida ? Colors.grey.shade200 : Colors.blue,
                        child: Icon(
                          Icons.notifications,
                          color: leida ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        evento?['nombre'] ?? 'Evento',
                        style: TextStyle(
                          fontWeight: leida
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['mensaje'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(
                              DateTime.parse(n['fecha_envio']).toLocal(),
                            ),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: leida
                          ? null
                          : TextButton(
                              onPressed: () => _markRead(n['id']),
                              child: const Text('Marcar leída'),
                            ),
                    );
                  },
                ),
    );
  }
}