import 'package:flutter/material.dart';

/// Tipos de notificación con colores y iconos propios.
enum AppNotificationType { success, error, warning, info, sync }

/// Widget de notificación premium con animación slide-down + fade.
///
/// Se muestra en la parte superior de la pantalla (como las notificaciones nativas de iOS/Android).
/// Desaparece automáticamente después de [duration].
class AppNotificationOverlay extends StatefulWidget {
  final String message;
  final String? subtitle;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AppNotificationOverlay({
    super.key,
    required this.message,
    this.subtitle,
    this.type = AppNotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<AppNotificationOverlay> createState() => _AppNotificationOverlayState();
}

class _AppNotificationOverlayState extends State<AppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Entrar
    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Configuración visual por tipo
  _NotificationStyle get _style => switch (widget.type) {
        AppNotificationType.success => _NotificationStyle(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.check_circle_rounded,
            iconBg: const Color(0xFF52B788),
            accentColor: const Color(0xFFB7E4C7),
          ),
        AppNotificationType.error => _NotificationStyle(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.cancel_rounded,
            iconBg: const Color(0xFFEF4444),
            accentColor: const Color(0xFFFECACA),
          ),
        AppNotificationType.warning => _NotificationStyle(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFFB45309)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFF59E0B),
            accentColor: const Color(0xFFFDE68A),
          ),
        AppNotificationType.sync => _NotificationStyle(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.cloud_sync_rounded,
            iconBg: const Color(0xFF38BDF8),
            accentColor: const Color(0xFFBAE6FD),
          ),
        AppNotificationType.info => _NotificationStyle(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.info_rounded,
            iconBg: const Color(0xFF818CF8),
            accentColor: const Color(0xFFC7D2FE),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                _dismiss();
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                gradient: style.gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: style.iconBg.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Efecto de brillo glassmorphism
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // Ícono con fondo circular
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: style.iconBg.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: style.iconBg.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(style.icon, color: style.accentColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          // Texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Botón cerrar
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Barra de progreso de tiempo
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _ProgressBar(
                        duration: widget.duration,
                        color: style.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _ProgressBar({required this.duration, required this.color});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return LinearProgressIndicator(
          value: 1.0 - _ctrl.value,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.color.withValues(alpha: 0.7),
          ),
          minHeight: 3,
        );
      },
    );
  }
}

class _NotificationStyle {
  final LinearGradient gradient;
  final IconData icon;
  final Color iconBg;
  final Color accentColor;

  const _NotificationStyle({
    required this.gradient,
    required this.icon,
    required this.iconBg,
    required this.accentColor,
  });
}
