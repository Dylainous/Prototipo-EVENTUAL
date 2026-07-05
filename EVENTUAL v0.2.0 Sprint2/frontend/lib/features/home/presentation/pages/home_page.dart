// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../events/presentation/pages/calendar_page.dart';
import '../../../events/presentation/bloc/events_bloc.dart';
import '../../../proposals/presentation/pages/propose_event_page.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';
import '../../../members/presentation/pages/members_page.dart';
import '../../../members/presentation/bloc/members_bloc.dart';

import '../../../contributions/presentation/bloc/contributions_bloc.dart';
import '../../../contributions/presentation/pages/contributions_page.dart';
import '../../../expenses/presentation/bloc/expenses_bloc.dart';
import '../../../expenses/presentation/pages/expenses_page.dart';
import '../../../event_registration/presentation/bloc/event_registration_bloc.dart';
import '../../../event_registration/presentation/pages/event_registration_page.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../../core/di/injection.dart';

import '../../../plan_event/presentation/bloc/plan_event_bloc.dart';
import '../../../plan_event/presentation/pages/plan_event_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _lastRol = '';  // ← agregar esto

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    final rol = authState is AuthAuthenticated ? authState.user.rol : 'Socio';
    // Si cambia el rol, resetear el índice
    if (rol != _lastRol) {
      _lastRol = rol;
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final rol = user?.rol ?? 'Socio';

    final isPresidente = rol == 'Presidente';
    final isSocio = rol == 'Socio';
    final isTesorero = rol == 'Tesorero';

    // ── Pestañas según rol ───────────────────────────────
    final tabs = [
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Calendario',
      ),
      if (isSocio)
        const NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Proponer',
        ),
      if (isPresidente)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Miembros',
        ),
      if (isPresidente)
        const NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Definir',
        ),
      if (isTesorero)
        const NavigationDestination(
          icon: Icon(Icons.monetization_on_outlined),
          selectedIcon: Icon(Icons.monetization_on),
          label: 'Aportes',
        ),
      if (isTesorero)
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Gastos',
        ),
    ];

    // ── Pantallas según rol ──────────────────────────────
    final screens = [
      // Tab 0: Calendario (todos los roles)
      BlocProvider(
        create: (_) => sl<EventsBloc>(),
        child: CalendarPage(rol: rol),
      ),

      // Tab 1 según rol
      if (isSocio)
        BlocProvider(
          create: (_) => sl<ProposalsBloc>(),
          child: const ProposeEventPage(),
        ),
      if (isPresidente)
        BlocProvider(
          create: (_) => sl<MembersBloc>(),
          child: const MembersPage(),
        ),
      if (isPresidente)
        BlocProvider(
          create: (_) => sl<PlanEventBloc>(),
          child: const PlanEventPage(),
        ),
      if (isTesorero)
        BlocProvider(
          create: (_) => sl<ContributionsBloc>(),
          child: const ContributionsPage(),
        ),
      if (isTesorero)
        BlocProvider(
          create: (_) => sl<ExpensesBloc>(),
          // Gastos requiere seleccionar el evento desde el calendario.
          // Esta pantalla muestra un aviso orientativo.
          child: const _GastosOrientacion(),
        ),
    ];

    // Protegemos el índice
final safeIndex = tabs.isEmpty
    ? 0
    : _selectedIndex.clamp(0, tabs.length - 1);

// Material 3 requiere mínimo 2 destinations
final bool showNavBar = tabs.length >= 2;

return Scaffold(
  appBar: AppBar(
    backgroundColor: const Color(0xFF1A237E),
    foregroundColor: Colors.white,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user?.nombreCompleto ?? 'Club de Suboficiales',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          rol,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () {
          context.read<AuthBloc>().add(AuthLogoutRequested());
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
    ],
  ),

  body: IndexedStack(
    index: safeIndex,
    children: screens,
  ),

  // SOLO mostramos NavigationBar si hay 2 o más tabs
  bottomNavigationBar: showNavBar
      ? NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) {
            setState(() => _selectedIndex = i);
          },
          destinations: tabs,
          backgroundColor: Colors.white,
          indicatorColor:
              const Color(0xFF1A237E).withOpacity(0.15),
        )
      : null,
);
  }
}

// ── Widget orientativo para gastos ──────────────────────────
// Los gastos se registran desde el detalle de un evento en el Calendario.
class _GastosOrientacion extends StatelessWidget {
  const _GastosOrientacion();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Para registrar gastos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ve al Calendario → selecciona un evento → presiona "Registrar Gasto".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('Ir al Calendario'),
              onPressed: () {
                // Navegar a la pestaña del calendario (índice 0)
                final state =
                    context.findAncestorStateOfType<_HomePageState>();
                state?.setState(() => state._selectedIndex = 0);
              },
            ),
          ],
        ),
      ),
    );
  }
}