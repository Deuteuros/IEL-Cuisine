import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cast_service.dart';

final castServiceProvider = ChangeNotifierProvider<CastService>((ref) {
  final service = CastService();
  ref.onDispose(() => service.dispose());
  return service;
});

class CastButtonWidget extends ConsumerStatefulWidget {
  const CastButtonWidget({super.key});

  @override
  ConsumerState<CastButtonWidget> createState() => _CastButtonWidgetState();
}

class _CastButtonWidgetState extends ConsumerState<CastButtonWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(castServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cast = ref.watch(castServiceProvider);

    if (cast.status == CastStatus.unavailable) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(
        _iconForStatus(cast.status),
        color: _colorForStatus(cast.status),
      ),
      tooltip: 'Chromecast / Android TV',
      onSelected: (value) async {
        switch (value) {
          case 'start_discovery':
            await ref.read(castServiceProvider).startDiscovery();
            break;
          case 'stop_cast':
            await ref.read(castServiceProvider).stopCast();
            break;
          case 'disconnect':
            await ref.read(castServiceProvider).disconnect();
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (cast.isCasting) {
          items.add(
            const PopupMenuItem(
              value: 'stop_cast',
              child: ListTile(
                leading: Icon(Icons.stop, color: Colors.red),
                title: Text('Arrêter le Cast'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
          items.add(
            const PopupMenuItem(
              value: 'disconnect',
              child: ListTile(
                leading: Icon(Icons.link_off),
                title: Text('Déconnecter'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
          return items;
        }

        if (cast.status == CastStatus.connected && cast.selectedDevice != null) {
          items.add(
            PopupMenuItem(
              value: 'start_cast',
              child: ListTile(
                leading: Icon(Icons.cast_connected, color: Colors.blue),
                title: Text('Diffuser sur ${cast.selectedDevice!.name}'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
          items.add(
            const PopupMenuDivider(),
          );
        }

        if (cast.devices.isEmpty) {
          items.add(
            const PopupMenuItem(
              value: 'start_discovery',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Rechercher des appareils'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
          items.add(
            PopupMenuItem(
              enabled: false,
              child: Text(
                'Aucun appareil trouvé',
                style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ),
          );
        } else {
          for (final device in cast.devices) {
            final isSelected = cast.selectedDevice?.id == device.id;
            items.add(
              PopupMenuItem(
                value: 'connect_${device.id}',
                child: ListTile(
                  leading: Icon(
                    isSelected ? Icons.cast_connected : Icons.cast,
                    color: isSelected ? Colors.blue : null,
                  ),
                  title: Text(device.name),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Colors.green, size: 18)
                      : null,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    if (!isSelected) {
                      ref.read(castServiceProvider).connect(device);
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          }
        }

        return items;
      },
    );
  }

  IconData _iconForStatus(CastStatus status) {
    switch (status) {
      case CastStatus.connecting:
        return Icons.cast_connected;
      case CastStatus.connected:
      case CastStatus.casting:
        return Icons.cast_connected;
      default:
        return Icons.cast;
    }
  }

  Color _colorForStatus(CastStatus status) {
    switch (status) {
      case CastStatus.connecting:
        return Colors.orange;
      case CastStatus.connected:
      case CastStatus.casting:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
