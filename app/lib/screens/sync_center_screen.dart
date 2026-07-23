import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';

class SyncCenterScreen extends StatelessWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Centro de Sincronización',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => sync.refreshPendingCount(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- Tarjeta de estado de conexión ---
                _buildStatusCard(context, sync),
                const SizedBox(height: 16),

                // --- Tarjeta de error (si la hubo) ---
                if (sync.lastError != null)
                  _buildErrorCard(context, sync.lastError!),

                // --- Tarjeta de pendientes ---
                const SizedBox(height: 8),
                _buildPendingCard(context, sync),
                const SizedBox(height: 16),

                // --- Tarjeta informativa ---
                _buildInfoCard(context, sync),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, SyncProvider sync) {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (sync.currentState) {
      case SyncState.synced:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        statusTitle = 'Sincronizado';
        statusSubtitle = 'Todos los datos están en el servidor.';
        break;
      case SyncState.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.cloud_upload;
        statusTitle = 'Conexión activa — Datos pendientes';
        statusSubtitle =
            '${sync.pendingCount} registro(s) esperando sincronización.';
        break;
      case SyncState.offline:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off;
        statusTitle = 'Sin conexión';
        statusSubtitle =
            'Los datos se guardan localmente y se sincronizarán cuando haya internet.';
        break;
      case SyncState.syncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusTitle = 'Sincronizando...';
        statusSubtitle = 'Enviando datos al servidor.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: sync.currentState == SyncState.syncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Icon(statusIcon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  statusSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, SyncProvider sync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions,
                  color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(width: 8),
              const Text('Pendiente por sincronizar',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: sync.pendingCount > 0
                      ? Colors.orange
                      : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${sync.pendingCount}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (sync.pendingCount == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('✅ Todo sincronizado',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Text(
              '${sync.pendingCount} registro(s) esperan ser enviados al servidor.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const Divider(height: 32),
                  ElevatedButton.icon(
            onPressed: (sync.currentState == SyncState.offline ||
                    sync.currentState == SyncState.syncing ||
                    sync.pendingCount == 0)
                ? null
                : () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final userId = authProvider.usuarioId;
                    final token = authProvider.token;

                    if (userId == null || token == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: No se encontró la sesión del usuario.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    final ok = await sync.syncDataNow(userId, token);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? '✅ Sincronización exitosa'
                              : '❌ Error: ${sync.lastError}'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
            icon: sync.currentState == SyncState.syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync),
            label: Text(sync.currentState == SyncState.syncing
                ? 'Sincronizando...'
                : 'Sincronizar Ahora'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SyncProvider sync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              const Text('Almacenamiento Local vs Nube',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Datos en nube (seguros)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              Text(
                sync.pendingCount == 0 ? '100%' : 'Actualizando...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: sync.pendingCount == 0 ? 1.0 : 0.0,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHigh,
            color: Colors.green,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Datos locales (pendientes)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              Text(
                '${sync.pendingCount} registros',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        sync.pendingCount > 0 ? Colors.orange : Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: sync.pendingCount > 10
                ? 1.0
                : sync.pendingCount / 10.0,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHigh,
            color: Colors.orange,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Text(
            'Los datos se guardan en el dispositivo para trabajar sin internet y se sincronizan automáticamente al conectarse.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
