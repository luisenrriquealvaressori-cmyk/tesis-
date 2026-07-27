// ============================================================================
// catalog_sync_service.dart
//
// Servicio que descarga los catálogos maestros desde el servidor (PostgreSQL)
// via la API REST y los guarda en la base de datos SQLite local.
//
// FLUJO CORRECTO:
//   PostgreSQL (servidor) → GET /api/sync/pull → SQLite (caché local)
//
// USO (llamar después de login o al iniciar la app con conexión):
//   final ok = await CatalogSyncService.downloadAndCache();
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_database.dart';
import '../config/api_config.dart';

class CatalogSyncService {
  CatalogSyncService._();

  static String get _baseUrl => ApiConfig.baseUrl;

  /// Descarga todos los catálogos del servidor y los guarda en SQLite.
  /// Retorna `true` si fue exitoso, `false` si hubo error de red.
  static Future<bool> downloadAndCache([String? token]) async {
    try {
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/sync/pull'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        debugPrint('[CatalogSync] HTTP Error ${response.statusCode}: ${response.body}');
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // --- Mapear la respuesta del servidor a los mapas que espera SQLite ---
      final List<Map<String, dynamic>> departamentos = ((data['departamentos'] ?? data['Departamentos']) as List? ?? [])
          .map((d) => {
                'id': (d['id'] ?? d['Id'])?.toString() ?? '',
                'nombre': (d['nombre'] ?? d['Nombre'])?.toString() ?? '',
              })
          .where((d) => (d['id'] as String).isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> municipios = ((data['municipios'] ?? data['Municipios']) as List? ?? [])
          .map((m) {
            final depId = (m['departamentoId'] ?? m['departamento_id'] ?? m['DepartamentoId'])?.toString();
            return {
              'id': (m['id'] ?? m['Id'])?.toString() ?? '',
              'departamento_id': (depId != null && depId.trim().isNotEmpty) ? depId.trim() : null,
              'nombre': (m['nombre'] ?? m['Nombre'])?.toString() ?? '',
            };
          })
          .where((m) => (m['id'] as String).isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> comarcas = ((data['comarcas'] ?? data['Comarcas']) as List? ?? [])
          .map((c) {
            final munId = (c['municipioId'] ?? c['municipio_id'] ?? c['MunicipioId'])?.toString();
            return {
              'id': (c['id'] ?? c['Id'])?.toString() ?? '',
              'municipio_id': (munId != null && munId.trim().isNotEmpty) ? munId.trim() : null,
              'nombre': (c['nombre'] ?? c['Nombre'])?.toString() ?? '',
            };
          })
          .where((c) => (c['id'] as String).isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> razas = ((data['razas'] ?? data['Razas']) as List? ?? [])
          .map((r) => {
                'id': (r['id'] ?? r['Id'])?.toString() ?? '',
                'nombre': (r['nombre'] ?? r['Nombre'])?.toString() ?? '',
                'proposito': (r['proposito'] ?? r['Proposito']) is int
                    ? (r['proposito'] ?? r['Proposito'])
                    : int.tryParse((r['proposito'] ?? r['Proposito'])?.toString() ?? '0') ?? 0,
              })
          .where((r) => (r['id'] as String).isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> enfermedades = ((data['enfermedades'] ?? data['Enfermedades']) as List? ?? [])
          .map((e) => {
                'id': (e['id'] ?? e['Id'])?.toString() ?? '',
                'nombre': (e['nombre'] ?? e['Nombre'])?.toString() ?? '',
                'descripcion': (e['descripcion'] ?? e['Descripcion'])?.toString() ?? '',
                'notificacion_obligatoria': (e['notificacionObligatoria'] ?? e['notificacion_obligatoria'] ?? e['NotificacionObligatoria']) == true ? 1 : 0,
              })
          .where((e) => (e['id'] as String).isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> sintomas = ((data['sintomas'] ?? data['Sintomas']) as List? ?? [])
          .map((s) {
            final enfId = (s['enfermedadId'] ?? s['enfermedad_id'] ?? s['EnfermedadId'])?.toString();
            return {
              'id': (s['id'] ?? s['Id'])?.toString() ?? '',
              'enfermedad_id': (enfId != null && enfId.trim().isNotEmpty) ? enfId.trim() : null,
              'nombre': (s['nombre'] ?? s['Nombre'])?.toString() ?? '',
            };
          })
          .where((s) => (s['id'] as String).isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> medicamentos = ((data['medicamentos'] ?? data['Medicamentos']) as List? ?? [])
          .map((m) => {
                'id': (m['id'] ?? m['Id'])?.toString() ?? '',
                'nombre_comercial': (m['nombreComercial'] ?? m['nombre_comercial'] ?? m['NombreComercial'])?.toString() ?? '',
                'principio_activo': (m['principioActivo'] ?? m['principio_activo'] ?? m['PrincipioActivo'])?.toString() ?? '',
                'via_administracion': (m['viaAdministracion'] ?? m['via_administracion'] ?? m['ViaAdministracion'])?.toString() ?? '',
                'dias_retiro_leche': (m['diasRetiroLeche'] ?? m['dias_retiro_leche'] ?? m['DiasRetiroLeche']) is int
                    ? (m['diasRetiroLeche'] ?? m['dias_retiro_leche'] ?? m['DiasRetiroLeche'])
                    : int.tryParse((m['diasRetiroLeche'] ?? m['dias_retiro_leche'] ?? m['DiasRetiroLeche'])?.toString() ?? '0') ?? 0,
              })
          .where((m) => (m['id'] as String).isNotEmpty)
          .toList();

      debugPrint('[CatalogSync] Éxito: Descargados ${departamentos.length} deptos, ${municipios.length} munis, ${comarcas.length} comarcas');

      // --- Guardar todo en SQLite mediante UPSERT (sin borrar tablas activas) ---
      await LocalDatabase.instance.upsertCatalogoBatch(
        departamentos: departamentos,
        municipios: municipios,
        comarcas: comarcas,
        razas: razas,
        enfermedades: enfermedades,
        sintomas: sintomas,
        medicamentos: medicamentos,
        clearFirst: false,
      );

      return true;
    } catch (e, stack) {
      debugPrint('[CatalogSync] Error al procesar catálogos: $e\n$stack');
      return false;
    }
  }

  /// No inserta ningún dato quemado ni ficticio.
  /// Todos los catálogos (departamentos, municipios, comarcas, etc.) se descargan
  /// 100% directamente desde la base de datos remota del servidor (Neon DB).
  static Future<void> ensureBaseCatalogs() async {
    return;
  }
}

