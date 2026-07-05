// lib/features/events/presentation/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../bloc/events_bloc.dart';
import '../../domain/entities/event_entity.dart';
import '../../../../core/utils/strategy.dart';

import '../../../plan_event/presentation/pages/quotations_page.dart';

class CalendarPage extends StatefulWidget {
  final String rol;  // ← agregar esto
  const CalendarPage({super.key, required this.rol});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _tipoFiltro = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final strategy = _buildStrategy();
    context.read<EventsBloc>().add(EventsLoadRequested(strategy: strategy));
  }

  // Strategy pattern: construir estrategia según filtros activos
  EventFilterStrategy _buildStrategy() {
    final hasTipo = _tipoFiltro != 'Todos';
    final year = _focusedDay.year;
    final month = _focusedDay.month;

    if (hasTipo) {
      return FilterByTypeAndMonthStrategy(_tipoFiltro, year, month);
    }
    return FilterByMonthStrategy(year, month);
  }

  List<EventEntity> _eventsForDay(List<EventEntity> all, DateTime day) {
    return all.where((e) => isSameDay(e.fecha, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Eventos'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) {
              setState(() => _tipoFiltro = v);
              // Strategy: cambiar filtro en tiempo real
              context.read<EventsBloc>().add(EventsFilterChanged(_buildStrategy()));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Todos', child: Text('Todos')),
              PopupMenuItem(value: 'Social', child: Text('Sociales')),
              PopupMenuItem(value: 'Deportivo', child: Text('Deportivos')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          final events = state is EventsLoaded ? state.events : <EventEntity>[];

          return Column(children: [
            // Leyenda de colores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                _legend(Colors.blue.shade700, 'Social'),
                const SizedBox(width: 16),
                _legend(Colors.green.shade700, 'Deportivo'),
                if (_tipoFiltro != 'Todos') ...[
                  const Spacer(),
                  Chip(
                    label: Text('Filtro: $_tipoFiltro'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _tipoFiltro = 'Todos');
                      context.read<EventsBloc>().add(
                            EventsFilterChanged(FilterByMonthStrategy(
                                _focusedDay.year, _focusedDay.month)));
                    },
                  ),
                ]
              ]),
            ),

            // Calendario mensual
            TableCalendar<EventEntity>(
              firstDay: DateTime(2025),
              lastDay: DateTime(2028),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: (day) => _eventsForDay(events, day),
              calendarStyle: CalendarStyle(
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.indigo.shade200,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF1A237E),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
                // Strategy: recargar al cambiar de mes
                context.read<EventsBloc>().add(
                      EventsFilterChanged(FilterByTypeAndMonthStrategy(
                        _tipoFiltro == 'Todos' ? '' : _tipoFiltro,
                        focusedDay.year,
                        focusedDay.month,
                      )));
              },
            ),

            const Divider(),

            // Lista de eventos del día seleccionado (o todos si no hay selección)
            Expanded(
              child: Builder(builder: (_) {
                if (state is EventsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is EventsEmpty) {
                  return const Center(
                    child: Text('No hay eventos programados para este mes'),
                  );
                }

                final dayEvents = _selectedDay != null
                    ? _eventsForDay(events, _selectedDay!)
                    : events;

                if (dayEvents.isEmpty) {
                  return Center(
                    child: Text(_selectedDay != null
                        ? 'Sin eventos el ${DateFormat('d/M/yyyy').format(_selectedDay!)}'
                        : 'Sin eventos'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: dayEvents.length,
                  // AQUÍ: Le pasamos el rol usando widget.rol
                  itemBuilder: (_, i) => _EventTile(event: dayEvents[i], rol: widget.rol), 
                );
              }),
            ),
          ]);
        },
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

class _EventTile extends StatelessWidget {
  final EventEntity event;
  final String rol; // <-- Agregamos el rol aquí

  const _EventTile({required this.event, required this.rol});

  @override
  Widget build(BuildContext context) {
    final isSocial = event.tipoEvento == 'Social';
    final color = isSocial ? Colors.blue.shade700 : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            isSocial ? Icons.people : Icons.sports_soccer,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(event.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${DateFormat('d MMM yyyy', 'es').format(event.fecha)} • ${event.hora}\n${event.lugar}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(event.tipoEvento,
                  style: TextStyle(color: color, fontSize: 11)),
            ),
          ],
        ),
        onTap: () {
          context.read<EventsBloc>().add(EventsDetailRequested(event.id));
          _showEventDetail(context, event);
        },
      ),
    );
  }

  void _showEventDetail(BuildContext context, EventEntity e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.nombre,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row(Icons.calendar_today, DateFormat('EEEE d MMMM yyyy', 'es').format(e.fecha)),
            _row(Icons.access_time, e.hora),
            _row(Icons.location_on, e.lugar),
            _row(Icons.category, e.tipoEvento),
            _row(Icons.info_outline, e.estado),
            if (e.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(e.descripcion!, style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 20),

            // AQUÍ AGREGAMOS LA VALIDACIÓN DEL ROL Y EL BOTÓN
            if (rol == 'Presidente' || rol == 'Tesorero')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.request_quote),
                  label: const Text('Cotizaciones'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Cierra el modal primero
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuotationsPage(
                          eventoId: e.id,          // Cambiado de evento['id'] a e.id
                          eventoNombre: e.nombre,  // Cambiado de evento['nombre'] a e.nombre
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
