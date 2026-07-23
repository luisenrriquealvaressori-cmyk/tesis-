import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSyncing;

  const CustomAppBar({
    super.key,
    this.title = 'Agro-UX Cattle',
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.agriculture, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
      actions: [
        Consumer<SyncProvider>(
          builder: (context, syncProvider, child) {
            IconData cloudIcon = Icons.cloud_off;
            Color iconColor = Colors.grey;

            if (syncProvider.currentState == SyncState.synced) {
              cloudIcon = Icons.cloud_done;
              iconColor = Colors.green;
            } else if (syncProvider.currentState == SyncState.pending) {
              cloudIcon = Icons.cloud_upload;
              iconColor = Colors.orange;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(cloudIcon, color: iconColor),
                  onPressed: () => context.push('/sync'),
                ),
                if (syncProvider.currentState == SyncState.pending)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${syncProvider.pendingCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Theme.of(context).colorScheme.outlineVariant,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
