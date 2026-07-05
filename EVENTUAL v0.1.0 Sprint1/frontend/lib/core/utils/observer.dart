// lib/core/utils/observer.dart
// ============================================================
// PATRÓN OBSERVER - Capa de presentación (Flutter)
//
// Permite que los BLoCs/Widgets reaccionen a eventos del sistema
// sin acoplamiento directo. Se usa en:
//   - RF2: Mostrar cambios de estado de miembros en UI
//   - RF4: Actualizar badge/contador de propuestas en tiempo real
//
// Extensible: RF5 (Confirmar Asistencia) puede suscribir un observer
// que actualice el contador de confirmados en el calendario.
// ============================================================

typedef ObserverCallback<T> = void Function(T data);

class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  final Map<String, List<ObserverCallback>> _listeners = {};

  /// Suscribirse a un evento
  void on<T>(String event, ObserverCallback<T> callback) {
    _listeners.putIfAbsent(event, () => []);
    _listeners[event]!.add((data) => callback(data as T));
  }

  /// Emitir un evento con datos
  void emit<T>(String event, T data) {
    final callbacks = _listeners[event];
    if (callbacks == null) return;
    for (final cb in callbacks) {
      cb(data);
    }
  }

  /// Cancelar suscripción (para dispose en widgets)
  void off(String event, ObserverCallback callback) {
    _listeners[event]?.remove(callback);
  }

  /// Eventos del sistema
  static const String memberUpdated = 'MEMBER_UPDATED';
  static const String memberDeactivated = 'MEMBER_DEACTIVATED';
  static const String proposalCreated = 'PROPOSAL_CREATED';
  // Extensión futura: static const String attendanceConfirmed = 'ATTENDANCE_CONFIRMED';
}
