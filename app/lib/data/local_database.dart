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
      version: 5,
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

    /// Síntomas vinculados a una enfermedad (enfermedad_id puede ser NULL si aplica a múltiples o en catálogos generales)
    await db.execute('''
CREATE TABLE IF NOT EXISTS sintomas (
  id             TEXT PRIMARY KEY,
  enfermedad_id  TEXT,
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

    /// Registros reproductivos de un animal
    await db.execute('''
CREATE TABLE IF NOT EXISTS registros_reproductivos (
  id             TEXT PRIMARY KEY,
  animal_id      TEXT NOT NULL,
  tipo_evento    TEXT NOT NULL,
  fecha_evento   TEXT NOT NULL,
  toro_id        TEXT,
  observaciones  TEXT,
  is_synced      INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (animal_id) REFERENCES animales(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reproductivos_animal_id ON registros_reproductivos(animal_id)');
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

    if (oldVersion < 4) {
      // Recrear tabla sintomas sin restricción NOT NULL en enfermedad_id
      await db.execute('DROP TABLE IF EXISTS registro_salud_sintomas;');
      await db.execute('DROP TABLE IF EXISTS sintomas;');
      await db.execute('''
CREATE TABLE IF NOT EXISTS sintomas (
  id             TEXT PRIMARY KEY,
  enfermedad_id  TEXT,
  nombre         TEXT NOT NULL,
  FOREIGN KEY (enfermedad_id) REFERENCES enfermedades(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
)
''');
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
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sintomas_enfermedad_id ON sintomas(enfermedad_id);');
    }

    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS registros_reproductivos (
  id             TEXT PRIMARY KEY,
  animal_id      TEXT NOT NULL,
  tipo_evento    TEXT NOT NULL,
  fecha_evento   TEXT NOT NULL,
  toro_id        TEXT,
  observaciones  TEXT,
  is_synced      INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (animal_id) REFERENCES animales(id)
    ON DELETE CASCADE ON UPDATE NO ACTION
)
''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_reproductivos_animal_id ON registros_reproductivos(animal_id)');
    }
  }

  // =========================================================================
  // CRUD: CATÁLOGOS (escritura batch desde sync con el servidor)
  // =========================================================================

  /// Reemplaza todos los catálogos descargados del servidor.
  /// Si [clearFirst] es true, limpia las tablas locales antes de insertar
  /// para reflejar únicamente lo que existe en la base de datos remota.
  Future<void> upsertCatalogoBatch({
    List<Map<String, dynamic>> razas = const [],
    List<Map<String, dynamic>> enfermedades = const [],
    List<Map<String, dynamic>> sintomas = const [],
    List<Map<String, dynamic>> medicamentos = const [],
    List<Map<String, dynamic>> departamentos = const [],
    List<Map<String, dynamic>> municipios = const [],
    List<Map<String, dynamic>> comarcas = const [],
    bool clearFirst = false,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      if (clearFirst) {
        // Borrar en orden jerárquico inverso para evitar violaciones de clave foránea
        if (comarcas.isNotEmpty) await txn.delete('comarcas');
        if (municipios.isNotEmpty) await txn.delete('municipios');
        if (departamentos.isNotEmpty) await txn.delete('departamentos');
        if (medicamentos.isNotEmpty) await txn.delete('medicamentos');
        if (sintomas.isNotEmpty) await txn.delete('sintomas');
        if (enfermedades.isNotEmpty) await txn.delete('enfermedades');
        if (razas.isNotEmpty) await txn.delete('razas');
      }

      for (final d in departamentos) {
        await txn.insert('departamentos', d, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final m in municipios) {
        final item = Map<String, dynamic>.from(m);
        if (item['departamento_id'] is String && (item['departamento_id'] as String).trim().isEmpty) {
          item['departamento_id'] = null;
        }
        await txn.insert('municipios', item, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final c in comarcas) {
        final item = Map<String, dynamic>.from(c);
        if (item['municipio_id'] is String && (item['municipio_id'] as String).trim().isEmpty) {
          item['municipio_id'] = null;
        }
        await txn.insert('comarcas', item, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final r in razas) {
        await txn.insert('razas', r, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final e in enfermedades) {
        await txn.insert('enfermedades', e, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final s in sintomas) {
        final item = Map<String, dynamic>.from(s);
        if (item['enfermedad_id'] is String && (item['enfermedad_id'] as String).trim().isEmpty) {
          item['enfermedad_id'] = null;
        }
        await txn.insert('sintomas', item, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final m in medicamentos) {
        await txn.insert('medicamentos', m, conflictAlgorithm: ConflictAlgorithm.ignore);
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
    return await db.query(
      'sintomas',
      where: 'enfermedad_id = ? OR enfermedad_id IS NULL OR enfermedad_id = ""',
      whereArgs: [enfermedadId],
      orderBy: 'nombre ASC',
    );
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

  /// Registros de salud de la finca (para dashboard y consulta).
  Future<List<Map<String, dynamic>>> getUltimosRegistrosSalud(
      String fincaId, {int? limite}) async {
    final db = await instance.database;
    final limitClause = (limite != null && limite > 0) ? 'LIMIT $limite' : '';
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
      $limitClause
    ''', [fincaId]);
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

  // =========================================================================
  // FÓRMULAS GANADERAS E INDICADORES KPI
  // =========================================================================

  /// 1. Cálculo de Unidades de Ganado Mayor (UGM) de la finca.
  /// Factores de conversión:
  /// - Toro reproductor (Macho > 24 meses): 1.2 UGM
  /// - Vaca adulta (Hembra > 24 meses): 1.0 UGM
  /// - Novillo / Vaquilla (12 - 24 meses): 0.7 UGM
  /// - Ternero / Ternera (< 12 meses): 0.4 UGM
  Future<double> getUnidadesGanadoMayor(String fincaId) async {
    final animales = await getAnimalesByFinca(fincaId);
    if (animales.isEmpty) return 0.0;

    final ahora = DateTime.now();
    double totalUGM = 0.0;

    for (final animal in animales) {
      final fechaNac = DateTime.tryParse(animal['fecha_nacimiento'] as String? ?? '') ?? ahora;
      final edadMeses = (ahora.difference(fechaNac).inDays / 30.44).floor();
      final sexo = animal['sexo'] as int? ?? 1;

      if (edadMeses >= 24) {
        totalUGM += (sexo == 2) ? 1.2 : 1.0; // Toro=1.2, Vaca=1.0
      } else if (edadMeses >= 12) {
        totalUGM += 0.7; // Vaquilla / Novillo
      } else {
        totalUGM += 0.4; // Ternero / Ternera
      }
    }
    return double.parse(totalUGM.toStringAsFixed(1));
  }

  /// 2. Animales actualmente en período de retiro sanitario de leche (Tiempo de Carencia).
  /// Si (fecha_deteccion + dias_retiro_leche) >= hoy, la leche debe descartarse.
  Future<List<Map<String, dynamic>>> getAnimalesEnRetiroLeche(String fincaId) async {
    final db = await instance.database;
    final ahoraStr = DateTime.now().toIso8601String().substring(0, 10);

    return await db.rawQuery('''
      SELECT DISTINCT
        a.id AS animal_id,
        a.identificacion,
        e.nombre AS enfermedad_nombre,
        m.nombre_comercial AS medicamento_nombre,
        m.dias_retiro_leche,
        rs.fecha_deteccion
      FROM registros_salud rs
      INNER JOIN animales a ON rs.animal_id = a.id
      INNER JOIN enfermedades e ON rs.enfermedad_id = e.id
      INNER JOIN tratamientos t ON t.registro_salud_id = rs.id
      INNER JOIN medicamentos m ON t.medicamento_id = m.id
      WHERE a.finca_id = ?
        AND rs.is_deleted = 0
        AND m.dias_retiro_leche > 0
        AND date(rs.fecha_deteccion, '+' || m.dias_retiro_leche || ' days') >= date(?)
      ORDER BY rs.fecha_deteccion DESC
    ''', [fincaId, ahoraStr]);
  }

  /// 3. Resumen completo de KPIs Ganaderos y Producción (Leche, UGM, Retiro, Promedios).
  Future<Map<String, dynamic>> getKPIsProduccion(String fincaId) async {
    final db = await instance.database;
    final hoy = DateTime.now();
    final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    // Total litros hoy
    final litrosHoy = await getLitrosHoy(fincaId);
    
    // Masa en Kg (1 L = 1.032 Kg)
    final kgLecheHoy = double.parse((litrosHoy * 1.032).toStringAsFixed(1));

    // Conteo vacas distintas ordeñadas hoy
    final resultVacas = await db.rawQuery('''
      SELECT COUNT(DISTINCT pl.animal_id) AS total_vacas
      FROM produccion_leche pl
      INNER JOIN animales a ON pl.animal_id = a.id
      WHERE a.finca_id = ?
        AND pl.is_deleted = 0
        AND pl.fecha LIKE ?
    ''', [fincaId, '$fechaStr%']);
    
    final vacasOrdenadasHoy = Sqflite.firstIntValue(resultVacas) ?? 0;
    
    // Promedio por vaca en ordeño hoy (L/vaca/día)
    final promedioVaca = vacasOrdenadasHoy > 0 
        ? double.parse((litrosHoy / vacasOrdenadasHoy).toStringAsFixed(1))
        : 0.0;

    // Total UGM
    final totalUGM = await getUnidadesGanadoMayor(fincaId);

    // Vacas en retiro por tratamiento médico
    final vacasEnRetiro = await getAnimalesEnRetiroLeche(fincaId);

    return {
      'litrosHoy': litrosHoy,
      'kgLecheHoy': kgLecheHoy,
      'vacasOrdenadasHoy': vacasOrdenadasHoy,
      'promedioVacaDia': promedioVaca,
      'totalUGM': totalUGM,
      'vacasEnRetiroCount': vacasEnRetiro.length,
      'vacasEnRetiro': vacasEnRetiro,
    };
  }

  /// Producción de los últimos 7 días agrupada por fecha para la gráfica
  Future<List<Map<String, dynamic>>> getProduccionUltimos7Dias(String fincaId) async {
    final db = await instance.database;
    final hoy = DateTime.now();
    final hace7Dias = hoy.subtract(const Duration(days: 6));
    final fechaInicioStr = '${hace7Dias.year}-${hace7Dias.month.toString().padLeft(2, '0')}-${hace7Dias.day.toString().padLeft(2, '0')}';
    
    return await db.rawQuery('''
      SELECT 
        substr(pl.fecha, 1, 10) as fecha_corta,
        SUM(pl.volumen_litros) as total_litros
      FROM produccion_leche pl
      INNER JOIN animales a ON pl.animal_id = a.id
      WHERE a.finca_id = ?
        AND pl.is_deleted = 0
        AND pl.fecha >= ?
      GROUP BY substr(pl.fecha, 1, 10)
      ORDER BY substr(pl.fecha, 1, 10) ASC
    ''', [fincaId, fechaInicioStr]);
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
  // REGISTROS REPRODUCTIVOS
  // =========================================================================
  Future<void> insertRegistroReproductivo(Map<String, dynamic> registro) async {
    final db = await instance.database;
    await db.insert(
      'registros_reproductivos',
      registro,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getRegistrosReproductivosByAnimal(String animalId) async {
    final db = await instance.database;
    return await db.query('registros_reproductivos',
        where: 'animal_id = ?',
        whereArgs: [animalId],
        orderBy: 'fecha_evento DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRegistrosReproductivos() async {
    final db = await instance.database;
    return await db.query('registros_reproductivos', where: 'is_synced = ?', whereArgs: [0]);
  }

  // =========================================================================
  // SYNC: Conteo de registros pendientes
  // =========================================================================

  Future<int> getPendingSyncCount() async {
    final db = await instance.database;
    int count = 0;

    final tables = ['fincas', 'animales', 'produccion_leche', 'registros_salud', 'tratamientos', 'registros_reproductivos'];
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

  /// Marca los tratamientos de un registro de salud como sincronizados
  Future<void> markTratamientosAsSyncedByRegistro(String registroSaludId) async {
    final db = await instance.database;
    await db.update('tratamientos', {'is_synced': 1}, where: 'registro_salud_id = ?', whereArgs: [registroSaludId]);
  }

  // =========================================================================
  // HELPERS: Métodos genéricos y filtrados adicionales
  // =========================================================================

  // =========================================================================
  // GESTIÓN DE SESIÓN: Limpieza de datos al cambiar de usuario
  // =========================================================================

  /// Borra **únicamente los datos operativos** del usuario (Bloque B):
  /// fincas, animales, producción de leche, registros de salud y tratamientos.
  ///
  /// Los catálogos (razas, enfermedades, medicamentos, geografía) se conservan
  /// ya que son datos globales del sistema, no pertenecen a ningún usuario.
  ///
  /// Debe llamarse en dos casos:
  /// 1. Al hacer logout (para que el siguiente usuario no vea datos ajenos).
  /// 2. Al detectar que el usuarioId del token nuevo ≠ al del token guardado.
  Future<void> clearUserData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Orden importante: respetar FK (hijos antes que padres)
      await txn.delete('registro_salud_sintomas');
      await txn.delete('tratamientos');
      await txn.delete('registros_salud');
      await txn.delete('registros_reproductivos');
      await txn.delete('produccion_leche');
      await txn.delete('animales');
      await txn.delete('fincas');
    });
  }

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
