import 'package:uuid/uuid.dart';

/// Generador de IDs determinísticos para el sistema offline-first de AgroStats.
///
/// ## ¿Por qué UUIDv5?
/// UUIDv5 genera un UUID a partir de un **namespace + nombre**, lo que garantiza:
/// - El mismo usuarioId + mismo nombre de entidad → SIEMPRE el mismo UUID.
/// - Funciona 100% offline, sin necesidad de conectarse al servidor.
/// - El servidor puede validar que el UUID pertenece al namespace del usuario
///   del JWT, detectando y rechazando intentos de inyectar datos ajenos.
///
/// ## Tipos de entidades
/// - **Fincas y Animales**: determinísticos (mismo nombre = mismo ID).
/// - **Registros transaccionales** (producción, salud): incluyen timestamp + aleatorio
///   para soportar múltiples registros del mismo tipo en el mismo día.
class IdGenerator {
  static const _uuid = Uuid();

  // Namespace base de la aplicación (fijo, no cambia nunca)
  static const String _appNamespace = 'agrostats.ganadero.nic';

  /// Genera el UUID de namespace del usuario.
  /// Sirve como raíz para todos los IDs de entidades de ese usuario.
  static String _userNamespace(String usuarioId) {
    return _uuid.v5(Namespace.url.value, '$_appNamespace:user:$usuarioId');
  }

  /// Genera un UUID v5 determinístico para cualquier entidad.
  ///
  /// - [usuarioId]: El ID del usuario autenticado (viene del servidor).
  /// - [entityKey]: Clave única dentro del dominio del usuario.
  ///   Ej: 'finca:Mi Finca Principal', 'animal:AAA-001'
  static String forEntity(String usuarioId, String entityKey) {
    final namespace = _userNamespace(usuarioId);
    return _uuid.v5(namespace, entityKey);
  }

  /// ID determinístico para una **finca**.
  ///
  /// La clave es el nombre de la finca (único por usuario).
  /// Reinstalar la app con el mismo nombre = mismo UUID = el servidor hace UPSERT.
  static String forFinca(String usuarioId, String fincaNombre) {
    return forEntity(usuarioId, 'finca:${fincaNombre.trim().toLowerCase()}');
  }

  /// ID determinístico para un **animal**.
  ///
  /// La clave es la identificación del animal (ej: "AAA-001"), única por finca.
  static String forAnimal(String usuarioId, String identificacion) {
    return forEntity(usuarioId, 'animal:${identificacion.trim().toUpperCase()}');
  }

  /// ID para **registros transaccionales** (producción de leche, registros de salud).
  ///
  /// Estos registros pueden haber múltiples por día por el mismo animal,
  /// por eso se usa timestamp + sufijo aleatorio para garantizar unicidad.
  /// Siguen incluyendo el usuarioId en el namespace para que el servidor
  /// pueda validar la propiedad del dato.
  static String forRecord(String usuarioId, String entityType) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = _uuid.v4().substring(0, 8);
    return forEntity(usuarioId, '$entityType:$ts:$rand');
  }

  /// ID para **tratamientos** (sub-entidad de un registro de salud).
  static String forTratamiento(String usuarioId, String registroSaludId, String medicamentoId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return forEntity(usuarioId, 'tratamiento:$registroSaludId:$medicamentoId:$ts');
  }
}
