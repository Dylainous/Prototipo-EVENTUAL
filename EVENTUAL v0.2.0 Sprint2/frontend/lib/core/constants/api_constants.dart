// lib/core/constants/api_constants.dart
class ApiConstants {
  ApiConstants._();

  // El ApiClient usará esta base internamente
  static const String baseUrl = 'http://localhost:3000/api'; 

  // Los endpoints deben ser SOLO la ruta relativa
  static const String login = '/auth/login';
  static const String members = '/members';
  static const String membersRoles = '/members/roles';
  static const String events = '/events';
  static const String proposals = '/proposals';
  static const String myProposals = '/proposals/mine';
}
