// lib/core/constants/api_constants.dart
class ApiConstants {
  ApiConstants._();

  // Cambiar por la URL real del backend desplegado
  static const String baseUrl = 'http://localhost:3000/api'; // Android emulator

  static const String login = '$baseUrl/auth/login';
  static const String members = '$baseUrl/members';
  static const String membersRoles = '$baseUrl/members/roles';
  static const String events = '$baseUrl/events';
  static const String proposals = '$baseUrl/proposals';
  static const String myProposals = '$baseUrl/proposals/mine';
}
