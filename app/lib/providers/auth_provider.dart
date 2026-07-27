import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/local_database.dart';

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
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nuevoUsuarioId = data['usuarioId'] as String;

        final prefs = await SharedPreferences.getInstance();
        final prevUsuarioId = prefs.getString('agro_userid');

        // CRÍTICO: Si el usuario que inicia sesión es diferente al que
        // tenía sesión anterior, limpiar todos los datos locales SQLite
        // para evitar que un ganadero vea datos de otro.
        if (prevUsuarioId != null && prevUsuarioId != nuevoUsuarioId) {
          await LocalDatabase.instance.clearUserData();
        }

        _token = data['token'];
        _usuarioId = nuevoUsuarioId;
        _nombre = data['nombre'];

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

  Future<bool> register({
    required String nombre,
    required String telefono,
    required String clave,
    required String municipioId,
    required String comarca,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'clave': clave,
          'municipioId': municipioId,
          'comarca': comarca,
        }),
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        // Intentar iniciar sesión automáticamente con las credenciales registradas
        return await login(telefono, clave);
      } else {
        final body = jsonDecode(response.body);
        _lastError = body['error'] ?? 'Error al registrar usuario';
      }
    } catch (e) {
      // Si la API no responde o se opera sin red, permitir sesión local temporal
      await setLocalSession(nombre: nombre, telefono: telefono);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> setLocalSession({required String nombre, required String telefono}) async {
    _token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
    _usuarioId = 'user_local_${DateTime.now().millisecondsSinceEpoch}';
    _nombre = nombre;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agro_token', _token!);
    await prefs.setString('agro_userid', _usuarioId!);
    await prefs.setString('agro_nombre', _nombre!);
    notifyListeners();
  }

  Future<void> logout() async {
    // Limpiar datos operativos del SQLite local antes de cerrar sesión.
    // Garantiza que el siguiente usuario que ingrese no vea datos ajenos.
    await LocalDatabase.instance.clearUserData();

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

