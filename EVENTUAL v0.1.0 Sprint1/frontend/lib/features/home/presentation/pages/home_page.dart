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
import '../../../../core/di/injection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  String get _userRole {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user.rol;
    return 'Socio';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final rol = user?.rol ?? 'Socio';
    final isPresidente = rol == 'Presidente';

    // Pestañas disponibles según rol
    final tabs = [
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Calendario',
      ),
      if (rol == 'Socio')
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
    ];

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
              style: const TextStyle(fontSize: 12, color: Colors.white70),
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
        index: _selectedIndex.clamp(0, tabs.length - 1),
        children: [
          // Tab 0: Calendario
          BlocProvider(
            create: (_) => sl<EventsBloc>(),
            child: const CalendarPage(),
          ),

          // Tab 1 (Socio): Proponer evento
          if (rol == 'Socio')
            BlocProvider(
              create: (_) => sl<ProposalsBloc>(),
              child: const ProposeEventPage(),
            ),

          // Tab 1 (Presidente): Gestionar Miembros
          if (isPresidente)
            BlocProvider(
              create: (_) => sl<MembersBloc>(),
              child: const MembersPage(),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: tabs,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A237E).withOpacity(0.15),
      ),
    );
  }
}
