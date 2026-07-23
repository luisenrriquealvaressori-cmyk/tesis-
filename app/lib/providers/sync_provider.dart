import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../data/local_database.dart';
import '../config/api_config.dart';

enum SyncState {
  synced,  // Internet OK, sin datos pendientes
  pending, // Hay datos pendientes por sincronizar
  offline, // Sin conexión a internet
  syncing, // Sincronización en progreso
}

class SyncProvider extends ChangeNotifier {
  SyncState _currentState = SyncState.offline;
  int _pendingCount = 0;
  bool _isConnected = false;
  String? _lastError;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  static String get _baseUrl => ApiConfig.baseUrl;

  SyncState get currentState => _currentState;
  int get pendingCount => _pendingCount;
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  SyncProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);

    await refreshPendingCount();
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    _isConnected = !results.contains(ConnectivityResult.none);
    _evaluateState();
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = await LocalDatabase.instance.getPendingSyncCount();
    _evaluateState();
  }

  void _evaluateState() {
    if (_currentState == SyncState.syncing) return; // No interrumpir sync en curso
    if (!_isConnected) {
      _currentState = SyncState.offline;
    } else if (_pendingCount > 0) {
      _currentState = SyncState.pending;
    } else {
      _currentState = SyncState.synced;
    }
    notifyListeners();
  }

  /// Sincroniza todos los registros pendientes con el servidor.
  /// Retorna `true` si fue exitoso.
  Future<bool> syncDataNow(String usuarioId, String token) async {
    if (!_isConnected || _pendingCount == 0) return false;

    _currentState = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Recopilar todos los datos pendientes de SQLite
      final fincas = await LocalDatabase.instance.getUnsyncedFincas();
      final animales = await LocalDatabase.instance.getUnsyncedAnimales();
      final produccion = await LocalDatabase.instance.getUnsyncedProduccion();
      final registrosSalud =
          await LocalDatabase.instance.getUnsyncedRegistrosSalud();

      // 2. Construir el payload para POST /api/sync/push
      final payload = {
        'usuarioId': usuarioId,
        'fincasNuevas': fincas.map(_mapFinca).toList(),
        'animalesNuevos': animales.map(_mapAnimal).toList(),
        'produccionLecheNuevos': produccion.map(_mapProduccion).toList(),
        'registrosSaludNuevos': registrosSalud.map(_mapRegistroSalud).toList(),
      };

      // 3. Enviar al servidor
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/sync/push'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // 4. Marcar todos los registros como sincronizados en SQLite
        for (final f in fincas) {
          await LocalDatabase.instance.markAsSynced('fincas', f['id'] as String);
        }
        for (final a in animales) {
          await LocalDatabase.instance.markAsSynced('animales', a['id'] as String);
        }
        for (final p in produccion) {
          await LocalDatabase.instance
              .markAsSynced('produccion_leche', p['id'] as String);
        }
        for (final rs in registrosSalud) {
          await LocalDatabase.instance
              .markAsSynced('registros_salud', rs['id'] as String);
        }

        await refreshPendingCount();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _lastError = body['error'] ?? 'Error del servidor: ${response.statusCode}';
        _currentState = SyncState.pending;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = 'Error de conexión: ${e.toString()}';
      _currentState = SyncState.pending;
      notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // Mappers: SQLite row → API DTO
  // =========================================================================
  Map<String, dynamic> _mapFinca(Map<String, dynamic> f) => {
        'id': f['id'],
        'municipioId': f['municipio_id'],
        'nombre': f['nombre'],
        'comarca': f['comarca'] ?? '',
        'lat': f['latitud'] ?? 0.0,
        'lng': f['longitud'] ?? 0.0,
      };

  Map<String, dynamic> _mapAnimal(Map<String, dynamic> a) => {
        'id': a['id'],
        'fincaId': a['finca_id'],
        'razaId': a['raza_id'],
        'identificacion': a['identificacion'],
        'sexo': a['sexo'],
        'fechaNacimiento': a['fecha_nacimiento'],
        'estado': a['estado'],
      };

  Map<String, dynamic> _mapProduccion(Map<String, dynamic> p) => {
        'id': p['id'],
        'animalId': p['animal_id'],
        'fecha': p['fecha'],
        'jornada': p['jornada'],
        'volumenLitros': p['volumen_litros'],
      };

  Map<String, dynamic> _mapRegistroSalud(Map<String, dynamic> rs) => {
        'id': rs['id'],
        'animalId': rs['animal_id'],
        'enfermedadId': rs['enfermedad_id'],
        'fechaDeteccion': rs['fecha_deteccion'],
        'observaciones': rs['observaciones'],
        'sintomasIdsMarcados': rs['sintomasIdsMarcados'] ?? [],
        'tratamientosNuevos': (rs['tratamientosNuevos'] as List<dynamic>?)
                ?.map((t) => {
                      'id': t['id'],
                      'medicamentoId': t['medicamento_id'],
                      'dosis': t['dosis_aplicada'],
                    })
                .toList() ??
            [],
      };

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
