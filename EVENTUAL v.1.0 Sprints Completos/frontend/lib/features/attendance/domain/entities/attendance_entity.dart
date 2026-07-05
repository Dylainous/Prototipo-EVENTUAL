class AttendanceEntity {
  final String id;
  final String eventoId;
  final String socioId;
  final bool asiste;
  final int numAcompanantes;
  final List<Map<String, dynamic>> acompanantes;
  final String? comentarios;
  final DateTime fechaConfirmacion;

  const AttendanceEntity({
    required this.id,
    required this.eventoId,
    required this.socioId,
    required this.asiste,
    required this.numAcompanantes,
    required this.acompanantes,
    this.comentarios,
    required this.fechaConfirmacion,
  });
}