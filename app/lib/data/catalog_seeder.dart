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
import 'package:http/http.dart' as http;
import 'local_database.dart';
import '../config/api_config.dart';

class CatalogSyncService {
  CatalogSyncService._();

  static String get _baseUrl => ApiConfig.baseUrl;

  /// Descarga todos los catálogos del servidor y los guarda en SQLite.
  /// Retorna `true` si fue exitoso, `false` si hubo error de red.
  static Future<bool> downloadAndCache(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/sync/pull'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // --- Mapear la respuesta del servidor a los mapas que espera SQLite ---
      // El servidor devuelve camelCase (System.Text.Json por defecto)

      final List<Map<String, dynamic>> departamentos = (data['departamentos'] as List)
          .map((d) => {
                'id': d['id'] as String,
                'nombre': d['nombre'] as String,
              })
          .toList();

      final List<Map<String, dynamic>> municipios = (data['municipios'] as List)
          .map((m) => {
                'id': m['id'] as String,
                'departamento_id': m['departamentoId'] as String,
                'nombre': m['nombre'] as String,
              })
          .toList();

      final List<Map<String, dynamic>> comarcas = (data['comarcas'] as List)
          .map((c) => {
                'id': c['id'] as String,
                'municipio_id': c['municipioId'] as String,
                'nombre': c['nombre'] as String,
              })
          .toList();

      final List<Map<String, dynamic>> razas = (data['razas'] as List)
          .map((r) => {
                'id': r['id'] as String,
                'nombre': r['nombre'] as String,
                'proposito': r['proposito'] as int,
              })
          .toList();

      final List<Map<String, dynamic>> enfermedades = (data['enfermedades'] as List)
          .map((e) => {
                'id': e['id'] as String,
                'nombre': e['nombre'] as String,
                'descripcion': e['descripcion'] as String,
                'notificacion_obligatoria': (e['notificacionObligatoria'] as bool) ? 1 : 0,
              })
          .toList();

      final List<Map<String, dynamic>> sintomas = (data['sintomas'] as List)
          .map((s) => {
                'id': s['id'] as String,
                'enfermedad_id': s['enfermedadId'] as String,
                'nombre': s['nombre'] as String,
              })
          .toList();

      final List<Map<String, dynamic>> medicamentos = (data['medicamentos'] as List)
          .map((m) => {
                'id': m['id'] as String,
                'nombre_comercial': m['nombreComercial'] as String,
                'principio_activo': m['principioActivo'] as String,
                'via_administracion': m['viaAdministracion'] as String,
                'dias_retiro_leche': m['diasRetiroLeche'] as int,
              })
          .toList();

      // --- Guardar todo en SQLite en un solo batch transaccional ---
      await LocalDatabase.instance.upsertCatalogoBatch(
        departamentos: departamentos,
        municipios: municipios,
        comarcas: comarcas,
        razas: razas,
        enfermedades: enfermedades,
        sintomas: sintomas,
        medicamentos: medicamentos,
      );

      return true;
    } catch (e) {
      // Error de red, timeout, o JSON inválido → los catálogos locales
      // existentes siguen siendo válidos para uso offline.
      return false;
    }
  }

  /// Siembra catálogos geográficos iniciales de respaldo en SQLite si la tabla de departamentos está vacía.
  static Future<void> ensureBaseCatalogs() async {
    final deptos = await LocalDatabase.instance.getAll('departamentos');
    if (deptos.isNotEmpty) return;

    final defaultDeptos = [
      {'id': 'depto-chontales', 'nombre': 'Chontales'},
      {'id': 'depto-boaco', 'nombre': 'Boaco'},
      {'id': 'depto-matagalpa', 'nombre': 'Matagalpa'},
      {'id': 'depto-managua', 'nombre': 'Managua'},
      {'id': 'depto-esteli', 'nombre': 'Estelí'},
      {'id': 'depto-rivas', 'nombre': 'Rivas'},
      {'id': 'depto-leon', 'nombre': 'León'},
      {'id': 'depto-rio-san-juan', 'nombre': 'Río San Juan'},
      {'id': 'depto-raccs', 'nombre': 'RACCS'},
      {'id': 'depto-raccn', 'nombre': 'RACCN'},
    ];

    final defaultMunis = [
      {'id': 'muni-juigalpa', 'departamento_id': 'depto-chontales', 'nombre': 'Juigalpa'},
      {'id': 'muni-acoyapa', 'departamento_id': 'depto-chontales', 'nombre': 'Acoyapa'},
      {'id': 'muni-santo-tomas', 'departamento_id': 'depto-chontales', 'nombre': 'Santo Tomás'},
      {'id': 'muni-camoapa', 'departamento_id': 'depto-boaco', 'nombre': 'Camoapa'},
      {'id': 'muni-boaco', 'departamento_id': 'depto-boaco', 'nombre': 'Boaco'},
      {'id': 'muni-matagalpa', 'departamento_id': 'depto-matagalpa', 'nombre': 'Matagalpa'},
      {'id': 'muni-sebaco', 'departamento_id': 'depto-matagalpa', 'nombre': 'Sébaco'},
      {'id': 'muni-tipitapa', 'departamento_id': 'depto-managua', 'nombre': 'Tipitapa'},
      {'id': 'muni-managua', 'departamento_id': 'depto-managua', 'nombre': 'Managua'},
      {'id': 'muni-esteli', 'departamento_id': 'depto-esteli', 'nombre': 'Estelí'},
      {'id': 'muni-tola', 'departamento_id': 'depto-rivas', 'nombre': 'Tola'},
      {'id': 'muni-el-rama', 'departamento_id': 'depto-raccs', 'nombre': 'El Rama'},
      {'id': 'muni-nueva-guinea', 'departamento_id': 'depto-raccs', 'nombre': 'Nueva Guinea'},
    ];

    final defaultComarcas = [
      {'id': 'com-1', 'municipio_id': 'muni-juigalpa', 'nombre': 'Puerto Díaz'},
      {'id': 'com-2', 'municipio_id': 'muni-juigalpa', 'nombre': 'Amerrisque'},
      {'id': 'com-3', 'municipio_id': 'muni-camoapa', 'nombre': 'Salinas'},
      {'id': 'com-4', 'municipio_id': 'muni-santo-tomas', 'nombre': 'El Zapote'},
    ];

    await LocalDatabase.instance.upsertCatalogoBatch(
      departamentos: defaultDeptos,
      municipios: defaultMunis,
      comarcas: defaultComarcas,
    );
  }
}

