/// Configuración global de la API del servidor.
class ApiConfig {
  ApiConfig._();

  /// URL base de la API backend.
  /// 10.0.2.2 es el alias de localhost para el Emulador de Android.
  /// Para dispositivos físicos en la misma red Wi-Fi, cambiar a IP local (ej: http://192.168.1.X:5151).
  static const String baseUrl = 'http://10.0.2.2:5151';
}
