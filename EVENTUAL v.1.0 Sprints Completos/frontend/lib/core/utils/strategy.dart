// lib/core/utils/strategy.dart
// ============================================================
// PATRÓN STRATEGY - Capa de presentación (Flutter)
//
// Estrategias de filtrado para el calendario de eventos (RF3).
// El BLoC del calendario recibe una estrategia e invoca buildParams()
// para construir los query params del request HTTP.
//
// Extensible: RF5 podría añadir FilterByConfirmedStrategy para
// mostrar solo eventos donde el socio ya confirmó asistencia.
// ============================================================

abstract class EventFilterStrategy {
  Map<String, String?> buildParams();
  String get label;
}

class AllEventsStrategy implements EventFilterStrategy {
  const AllEventsStrategy();

  @override
  Map<String, String?> buildParams() => {};

  @override
  String get label => 'Todos';
}

class FilterByTypeStrategy implements EventFilterStrategy {
  final String tipo; // 'Social' | 'Deportivo'
  const FilterByTypeStrategy(this.tipo);

  @override
  Map<String, String?> buildParams() => {'tipo': tipo};

  @override
  String get label => tipo;
}

class FilterByMonthStrategy implements EventFilterStrategy {
  final int year;
  final int month;
  const FilterByMonthStrategy(this.year, this.month);

  @override
  Map<String, String?> buildParams() => {
        'year': year.toString(),
        'month': month.toString(),
      };

  @override
  String get label => '$month/$year';
}

class FilterByTypeAndMonthStrategy implements EventFilterStrategy {
  final String tipo;
  final int year;
  final int month;
  const FilterByTypeAndMonthStrategy(this.tipo, this.year, this.month);

  @override
  Map<String, String?> buildParams() => {
        'tipo': tipo,
        'year': year.toString(),
        'month': month.toString(),
      };

  @override
  String get label => '$tipo - $month/$year';
}

/// Contexto que usa la estrategia activa
class EventFilterContext {
  EventFilterStrategy _strategy;

  EventFilterContext(this._strategy);

  void setStrategy(EventFilterStrategy strategy) {
    _strategy = strategy;
  }

  Map<String, String?> buildParams() => _strategy.buildParams();

  String get currentLabel => _strategy.label;
}
