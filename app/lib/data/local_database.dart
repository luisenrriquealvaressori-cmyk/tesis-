import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Base de datos SQLite local para uso offline-first.
/// Espejo del esquema PostgreSQL del servidor (Bloque B operativo).
/// Las tablas de catálogos (razas, enfermedades, etc.) se cachean
/// en tablas separadas de solo lectura para poblar los formularios.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agro_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      // CRÍTICO: Habilitar integridad referencial en SQLite
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  // =========================================================================
  // CREACIÓN DEL ESQUEMA v3
  // =========================================================================
  Future<void> _createDB(Database db, int version) async {
    // Activar FK en la sesión actual también
    await db.execute('PRAGMA foreign_keys = ON;');

    // -----------------------------------------------------------------
    // BLOQUE A: CATÁLOGOS (solo lectura, descargados del servidor)
    // -----------------------------------------------------------------

    /// Razas bovinas (Proposito: 1=Leche, 2=Carne, 3=Doble)
    await db.execute('''
CREATE TABLE IF NOT EXISTS razas (
  id          TEXT PRIMARY KEY,
  nombre      TEXT NOT NULL,
  proposito   INTEGER NOT NULL
)
''');

    /// Enfermedades clínicas
    await db.execute('''
CREATE TABLE IF NOT EXISTS enfermedades (
  id                       TEXT PRIMARY KEY,
  nombre                   TEXT NOT NULL,
  descripcion              TEXT NOT NULL,
  notificacion_obligatoria INTEGER NOT NULL DEFAULT 0
)
''');

    /// Síntomas vinculados a una enfermedad
    await db.execute('''
CREATE TABLE IF NOT EXISTS sintomas (
  id             TEXT PRIMARY KEY,
  enfermedad_id  TEXT NOT NULL,
  nombre         TEXT NOT NULL,
  FOREIGN KEY (enfermedad_id) REFERENCES enfermedades(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
)
''');

    /// Medicamentos veterinarios
    await db.execute('''
CREATE TABLE IF NOT EXISTS medicamentos (
  id                   TEXT PRIMARY KEY,
  nombre_comercial     TEXT NOT NULL,
  principio_activo     TEXT NOT NULL,
  via_administracion   TEXT NOT NULL,
  dias_retiro_leche    INTEGER NOT NULL DEFAULT 0
)
''');

    /// Departamentos geográficos
    await db.execute('''
CREATE TABLE IF NOT EXISTS departamentos (
  id      TEXT PRIMARY KEY,
  nombre  TEXT NOT NULL
)
''');

    /// Municipios (dependen de Departamentos)
    await db.execute('''
CREATE TABLE IF NOT EXISTS municipios (
  id               TEXT PRIMARY KEY,
  departamento_id  TEXT NOT NULL,
  nombre           TEXT NOT NULL,
  FOREIGN KEY (departamento_id) REFERENCES departamentos(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
)
''');

    /// Comarcas (dependen de Municipios)
    await db.execute('''
CREATE TABLE IF NOT EXISTS comarcas (
  id            TEXT PRIMARY KEY,
  municipio_id  TEXT NOT NULL,
  nombre        TEXT NOT NULL,
  FOREIGN KEY (municipio_id) REFERENCES municipios(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
)
''');

    // -----------------------------------------------------------------
    // BLOQUE B: DATOS OPERATIVOS (generados en el móvil, se sincronizan)
    // -----------------------------------------------------------------

    /// Finca del ganadero
    /// is_synced: 0=Pendiente, 1=Sincronizado
    await db.execute('''
CREATE TABLE IF NOT EXISTS fincas (
  id              TEXT PRIMARY KEY,
  nombre          TEXT NOT NULL,
  municipio_id    TEXT NOT NULL,
  comarca         TEXT NOT NULL,
  latitud         REAL NOT NULL DEFAULT 0.0,
  longitud        REAL NOT NULL DEFAULT 0.0,
  created_at      TEXT NOT NULL,
  is_deleted      INTEGER NOT NULL DEFAULT 0,
  is_synced       INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (municipio_id) REFERENCES municipios(id)
    ON DELETE RESTRICT ON UPDATE NO ACTION
)
''');

    /// Animales registrados en una finca
    /// sexo: 1=Hembra, 2=Macho
    /// estado: 1=Sana, 2=Enferma, 3=En Tratamiento
    await db.execute('''
CREATE TABLE IF NOT EXISTS animales (
  id               TEXT PRIMARY KEY,
  finca_id         TEXT NOT NULL,
  raza_id          TEXT NOT NULL,
  identificacion   TEXT NOT NULL,
  sexo             INTEGER NOT NULL,
  fecha_nacimiento TEXT NOT NULL,
  estado           INTEGER NOT NULL DEFAULT 1,
  created_at       TEXT NOT NULL,
  is_deleted       INTEGER NOT NULL DEFAULT 0,
  is_synced        INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (finca_id)  REFERENCES fincas(id)
    ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (raza_id)   REFERENCES razas(id)
    ON DELETE RESTRICT ON UPDATE NO ACTION
)
''');

    /// Producción de leche por animal
    /// jornada: 1=AM, 2=PM
    await db.execute('''
CREATE TABLE IF NOT EXISTS produccion_leche (
  id             TEXT PRIMARY KEY,
  animal_id      TEXT NOT NULL,
  fecha          TEXT NOT NULL,
  jornada        INTEGER NOT NULL,
  volumen_litros REAL NOT NULL DEFAULT 0.0,
  created_at     TEXT NOT NULL,
  is_deleted     INTEGER NOT NULL DEFAULT 0,
  is_synced      INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (animal_id) REFERENCES animales(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
)
''');

    /// Registros de salud / eventos médicos de un animal
    await db.execute('''
CREATE TABLE IF NOT EXISTS registros_salud (
  id               TEXT PRIMARY KEY,
  animal_id        TEXT NOT NULL,
  enfermedad_id    TEXT NOT NULL,
  fecha_deteccion  TEXT NOT NULL,
  observaciones    TEXT,
  created_at       TEXT NOT NULL,
  is_deleted       INTEGER NOT NULL DEFAULT 0,
  is_synced        INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (animal_id)     REFERENCES animales(id)
    ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (enfermedad_id) REFERENCES enfermedades(id)
    ON DELETE RESTRICT ON UPDATE NO ACTION
)
''');

    /// Síntomas observados en un registro de salud (tabla pivote M:N)
    await db.execute('''
CREATE TABLE IF NOT EXISTS registro_salud_sintomas (
  registro_salud_id  TEXT NOT NULL,
  sintoma_id         TEXT NOT NULL,
  PRIMARY KEY (registro_salud_id, sintoma_id),
  FOREIGN KEY (registro_salud_id) REFERENCES registros_salud(id)
    ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (sintoma_id)        REFERENCES sintomas(id)
    ON DELETE RESTRICT ON UPDATE NO ACTION
)
''');

    /// Tratamientos aplicados dentro de un registro de salud
    await db.execute('''
CREATE TABLE IF NOT EXISTS tratamientos (
  id                 TEXT PRIMARY KEY,
  registro_salud_id  TEXT NOT NULL,
  medicamento_id     TEXT NOT NULL,
  dosis_aplicada     REAL NOT NULL DEFAULT 0.0,
  created_at         TEXT NOT NULL,
  is_synced          INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (registro_salud_id) REFERENCES registros_salud(id)
    ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (medicamento_id)    REFERENCES medicamentos(id)
    ON DELETE RESTRICT ON UPDATE NO ACTION
)
''');

    // Índices para acelerar consultas frecuentes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_animales_finca_id ON animales(finca_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_animales_is_synced ON animales(is_synced)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_produccion_animal_id ON produccion_leche(animal_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_produccion_fecha ON produccion_leche(fecha)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_registros_salud_animal_id ON registros_salud(animal_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tratamientos_registro_id ON tratamientos(registro_salud_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sintomas_enfermedad_id ON sintomas(enfermedad_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_municipios_depto_id ON municipios(departamento_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_comarcas_municipio_id ON comarcas(municipio_id)');
  }

  // =========================================================================
  // MIGRACIÓN v1 → v3 (para instancias existentes)
  // =========================================================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Eliminar tablas antiguas con nombres distintos
      await db.execute('DROP TABLE IF EXISTS farms');
      await db.execute('DROP TABLE IF EXISTS animals');
      await db.execute('DROP TABLE IF EXISTS health_records');
      await db.execute('DROP TABLE IF EXISTS milking_records');
      // Crear el esquema nuevo
      await _createDB(db, newVersion);
    }
    
    if (oldVersion == 2) {
      // Modificar tabla existente de animales para añadir 'estado'
      await db.execute('ALTER TABLE animales ADD COLUMN estado INTEGER NOT NULL DEFAULT 1;');
    }
  }

  // =========================================================================
  // CRUD: CATÁLOGOS (escritura batch desde sync con el servidor)
  // =========================================================================

  /// Reemplaza todos los catálogos descargados del servidor
  Future<void> upsertCatalogoBatch({
    List<Map<String, dynamic>> razas = const [],
    List<Map<String, dynamic>> enfermedades = const [],
    List<Map<String, dynamic>> sintomas = const [],
    List<Map<String, dynamic>> medicamentos = const [],
    List<Map<String, dynamic>> departamentos = const [],
    List<Map<String, dynamic>> municipios = const [],
    List<Map<String, dynamic>> comarcas = const [],
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (final r in razas) {
        await txn.insert('razas', r, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final e in enfermedades) {
        await txn.insert('enfermedades', e, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final s in sintomas) {
        await txn.insert('sintomas', s, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final m in medicamentos) {
        await txn.insert('medicamentos', m, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final d in departamentos) {
        await txn.insert('departamentos', d, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final m in municipios) {
        await txn.insert('municipios', m, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final c in comarcas) {
        await txn.insert('comarcas', c, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRazas() async {
    final db = await instance.database;
    return await db.query('razas', orderBy: 'nombre ASC');
  }

  Future<List<Map<String, dynamic>>> getEnfermedades() async {
    final db = await instance.database;
    return await db.query('enfermedades', orderBy: 'nombre ASC');
  }

  Future<List<Map<String, dynamic>>> getSintomasByEnfermedad(String enfermedadId) async {
    final db = await instance.database;
    return await db.query('sintomas', where: 'enfermedad_id = ?', whereArgs: [enfermedadId]);
  }

  Future<List<Map<String, dynamic>>> getMedicamentos() async {
    final db = await instance.database;
    return await db.query('medicamentos', orderBy: 'nombre_comercial ASC');
  }

  Future<List<Map<String, dynamic>>> getMunicipios() async {
    final db = await instance.database;
    return await db.query('municipios', orderBy: 'nombre ASC');
  }

  Future<List<Map<String, dynamic>>> getComarcasByMunicipio(String municipioId) async {
    final db = await instance.database;
    return await db.query('comarcas', where: 'municipio_id = ?', whereArgs: [municipioId]);
  }

  // =========================================================================
  // CRUD: FINCAS
  // =========================================================================

  Future<void> insertFinca(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('fincas', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getFinca() async {
    final db = await instance.database;
    final result = await db.query('fincas', where: 'is_deleted = ?', whereArgs: [0], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // =========================================================================
  // CRUD: ANIMALES
  // =========================================================================

  Future<void> insertAnimal(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('animales', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAnimalesByFinca(String fincaId) async {
    final db = await instance.database;
    return await db.query('animales',
        where: 'finca_id = ? AND is_deleted = ?', whereArgs: [fincaId, 0]);
  }

  /// Animales con nombre de raza incluido (JOIN) para la pantalla Mi Ganado.
  Future<List<Map<String, dynamic>>> getAnimalesConRaza(String fincaId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        a.id,
        a.identificacion,
        a.sexo,
        a.fecha_nacimiento,
        a.is_synced,
        r.nombre      AS raza_nombre,
        r.proposito   AS raza_proposito
      FROM animales a
      LEFT JOIN razas r ON a.raza_id = r.id
      WHERE a.finca_id = ? AND a.is_deleted = 0
      ORDER BY a.identificacion ASC
    ''', [fincaId]);
  }

  /// Total de animales activos en una finca.
  Future<int> getTotalAnimales(String fincaId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM animales WHERE finca_id = ? AND is_deleted = 0',
      [fincaId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Litros totales de leche del día de hoy (AM + PM).
  Future<double> getLitrosHoy(String fincaId) async {
    final db = await instance.database;
    final hoy = DateTime.now();
    final fechaStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(pl.volumen_litros), 0.0) AS total
      FROM produccion_leche pl
      INNER JOIN animales a ON pl.animal_id = a.id
      WHERE a.finca_id = ?
        AND pl.is_deleted = 0
        AND pl.fecha LIKE ?
    ''', [fincaId, '$fechaStr%']);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Últimos registros de salud de la finca (para dashboard).
  Future<List<Map<String, dynamic>>> getUltimosRegistrosSalud(
      String fincaId, {int limite = 3}) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        rs.id,
        rs.fecha_deteccion,
        rs.observaciones,
        a.identificacion  AS animal_id,
        e.nombre          AS enfermedad_nombre,
        e.notificacion_obligatoria
      FROM registros_salud rs
      INNER JOIN animales   a ON rs.animal_id     = a.id
      INNER JOIN enfermedades e ON rs.enfermedad_id = e.id
      WHERE a.finca_id = ? AND rs.is_deleted = 0
      ORDER BY rs.fecha_deteccion DESC
      LIMIT ?
    ''', [fincaId, limite]);
  }

  /// Historial médico de un animal específico con enfermedad y medicamentos.
  Future<List<Map<String, dynamic>>> getHistorialSaludAnimal(
      String animalId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT
        rs.id,
        rs.fecha_deteccion,
        rs.observaciones,
        e.nombre     AS enfermedad_nombre,
        e.notificacion_obligatoria,
        m.nombre_comercial,
        m.dias_retiro_leche,
        t.dosis_aplicada
      FROM registros_salud rs
      INNER JOIN enfermedades e ON rs.enfermedad_id = e.id
      LEFT  JOIN tratamientos t ON t.registro_salud_id = rs.id
      LEFT  JOIN medicamentos  m ON t.medicamento_id   = m.id
      WHERE rs.animal_id = ? AND rs.is_deleted = 0
      ORDER BY rs.fecha_deteccion DESC
    ''', [animalId]);
  }

  /// Medicamentos sugeridos para una enfermedad (basado en historial de la finca).
  /// Devuelve los medicamentos más usados para esa enfermedad en orden de frecuencia.
  Future<List<Map<String, dynamic>>> getMedicamentosSugeridos(
      String enfermedadId) async {
    final db = await instance.database;
    // Primero intentar con historial real de la finca
    final historial = await db.rawQuery('''
      SELECT
        m.id,
        m.nombre_comercial,
        m.principio_activo,
        m.via_administracion,
        m.dias_retiro_leche,
        COUNT(*) AS frecuencia
      FROM tratamientos t
      INNER JOIN medicamentos  m  ON t.medicamento_id   = m.id
      INNER JOIN registros_salud rs ON t.registro_salud_id = rs.id
      WHERE rs.enfermedad_id = ?
      GROUP BY m.id
      ORDER BY frecuencia DESC
      LIMIT 3
    ''', [enfermedadId]);
    // Si no hay historial, devolver lista vacía (se usará el dropdown normal)
    return historial;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAnimales() async {
    final db = await instance.database;
    return await db.query('animales', where: 'is_synced = ?', whereArgs: [0]);
  }

  // =========================================================================
  // CRUD: PRODUCCIÓN DE LECHE
  // =========================================================================

  Future<void> insertProduccionLeche(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('produccion_leche', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProduccionByAnimal(String animalId) async {
    final db = await instance.database;
    return await db.query('produccion_leche',
        where: 'animal_id = ? AND is_deleted = ?',
        whereArgs: [animalId, 0],
        orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedProduccion() async {
    final db = await instance.database;
    return await db.query('produccion_leche', where: 'is_synced = ?', whereArgs: [0]);
  }

  // =========================================================================
  // CRUD: REGISTROS DE SALUD
  // =========================================================================

  Future<void> insertRegistroSalud(
    Map<String, dynamic> registro,
    List<String> sintomaIds,
    List<Map<String, dynamic>> tratamientos,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('registros_salud', registro, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final sintomaId in sintomaIds) {
        await txn.insert('registro_salud_sintomas', {
          'registro_salud_id': registro['id'],
          'sintoma_id': sintomaId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final tratamiento in tratamientos) {
        await txn.insert('tratamientos', tratamiento,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRegistrosSaludByAnimal(String animalId) async {
    final db = await instance.database;
    return await db.query('registros_salud',
        where: 'animal_id = ? AND is_deleted = ?',
        whereArgs: [animalId, 0],
        orderBy: 'fecha_deteccion DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRegistrosSalud() async {
    final db = await instance.database;
    final registros = await db.query('registros_salud', where: 'is_synced = ?', whereArgs: [0]);
    
    List<Map<String, dynamic>> completos = [];
    for (var rs in registros) {
      final registroModificable = Map<String, dynamic>.from(rs);
      
      final sintomas = await db.query('registro_salud_sintomas', 
          where: 'registro_salud_id = ?', whereArgs: [rs['id']]);
      registroModificable['sintomasIdsMarcados'] = sintomas.map((s) => s['sintoma_id']).toList();
      
      final tratamientos = await db.query('tratamientos',
          where: 'registro_salud_id = ?', whereArgs: [rs['id']]);
      registroModificable['tratamientosNuevos'] = tratamientos;
      
      completos.add(registroModificable);
    }
    
    return completos;
  }

  // =========================================================================
  // SYNC: Conteo de registros pendientes
  // =========================================================================

  Future<int> getPendingSyncCount() async {
    final db = await instance.database;
    int count = 0;

    final tables = ['fincas', 'animales', 'produccion_leche', 'registros_salud', 'tratamientos'];
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) FROM $table WHERE is_synced = 0');
      count += Sqflite.firstIntValue(result) ?? 0;
    }

    return count;
  }

  /// Marca un registro como sincronizado
  Future<void> markAsSynced(String table, String id) async {
    final db = await instance.database;
    await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================================
  // HELPERS: Métodos genéricos y filtrados adicionales
  // =========================================================================

  /// Obtiene todos los registros de una tabla catálogo sin filtros.
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await instance.database;
    return await db.query(table, orderBy: 'nombre ASC');
  }

  /// Municipios filtrados por departamento (para el dropdown en cascada de farm_setup).
  Future<List<Map<String, dynamic>>> getMunicipiosByDepartamento(
      String departamentoId) async {
    final db = await instance.database;
    return await db.query(
      'municipios',
      where: 'departamento_id = ?',
      whereArgs: [departamentoId],
      orderBy: 'nombre ASC',
    );
  }

  /// Fincas pendientes de sincronizar.
  Future<List<Map<String, dynamic>>> getUnsyncedFincas() async {
    final db = await instance.database;
    return await db.query('fincas', where: 'is_synced = ?', whereArgs: [0]);
  }
}
