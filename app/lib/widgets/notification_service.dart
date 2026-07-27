import 'package:flutter/material.dart';
import 'app_notification.dart';

/// Servicio global para mostrar notificaciones premium desde cualquier pantalla.
///
/// ## Uso
/// ```dart
/// // En cualquier widget con BuildContext:
/// AppNotificationService.show(
///   context,
///   message: '✅ Animal guardado exitosamente',
///   subtitle: 'AAA-001 registrado en tu finca',
///   type: AppNotificationType.success,
/// );
/// ```
class AppNotificationService {
  static OverlayEntry? _currentEntry;

  /// Muestra una notificación premium en la parte superior de la pantalla.
  ///
  /// - [message]: Texto principal (corto, máx ~40 chars)
  /// - [subtitle]: Texto secundario opcional (descripción)
  /// - [type]: Tipo visual (success, error, warning, info, sync)
  /// - [duration]: Tiempo visible (por defecto 3 segundos)
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Descartar notificación anterior si todavía está visible
    _dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: AppNotificationOverlay(
            message: message,
            subtitle: subtitle,
            type: type,
            duration: duration,
            onDismiss: _dismiss,
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);
  }

  // ─── Shortcuts por tipo ─────────────────────────────────────────────────────

  static void success(BuildContext context, String message, {String? subtitle}) {
    show(context, message: message, subtitle: subtitle, type: AppNotificationType.success);
  }

  static void error(BuildContext context, String message, {String? subtitle}) {
    show(context, message: message, subtitle: subtitle, type: AppNotificationType.error,
        duration: const Duration(seconds: 4));
  }

  static void warning(BuildContext context, String message, {String? subtitle}) {
    show(context, message: message, subtitle: subtitle, type: AppNotificationType.warning);
  }

  static void info(BuildContext context, String message, {String? subtitle}) {
    show(context, message: message, subtitle: subtitle, type: AppNotificationType.info);
  }

  static void sync(BuildContext context, String message, {String? subtitle}) {
    show(context, message: message, subtitle: subtitle, type: AppNotificationType.sync);
  }

  static void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
