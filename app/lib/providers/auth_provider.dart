import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _usuarioId;
  String? _nombre;
  bool _isLoading = false;
  String? _lastError;

  static String get _baseUrl => ApiConfig.baseUrl; 

  String? get token => _token;
  String? get usuarioId => _usuarioId;
  String? get nombre => _nombre;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('agro_token');
    _usuarioId = prefs.getString('agro_userid');
    _nombre = prefs.getString('agro_nombre');
    notifyListeners();
  }

  Future<bool> login(String telefono, String clave) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telefono': telefono, 'clave': clave}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _usuarioId = data['usuarioId'];
        _nombre = data['nombre'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('agro_token', _token!);
        await prefs.setString('agro_userid', _usuarioId!);
        await prefs.setString('agro_nombre', _nombre!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _lastError = body['error'] ?? 'Credenciales incorrectas';
      }
    } catch (e) {
      _lastError = 'Error de conexión: Verifica tu red';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _usuarioId = null;
    _nombre = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('agro_token');
    await prefs.remove('agro_userid');
    await prefs.remove('agro_nombre');
    notifyListeners();
  }
}
