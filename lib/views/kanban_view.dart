import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/network_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/wakelock_provider.dart';
import '../providers/sync_inbox_provider.dart';
import '../services/network_client_service.dart';
import '../ui/widgets/cast_button_widget.dart';
import 'network_connection_view.dart';

class KanbanView extends ConsumerWidget {
  const KanbanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);

    final aFaireOrders = orders.where((o) => o.status == OrderStatus.aFaire).toList();
    final enCoursOrders = orders.where((o) => o.status == OrderStatus.enCours).toList();
    final faitOrders = orders.where((o) => o.status == OrderStatus.fait).toList();

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    ref.read(wakelockProvider);

    ref.listen(syncInboxProvider, (prev, next) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncInboxProvider).initialize();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE64A19).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Color(0xFFFF5722),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Lakozia',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final network = ref.watch(networkClientProvider);
              final Color statusColor;
              final IconData statusIcon;
              switch (network.status) {
                case ConnectionStatus.connected:
                  statusColor = Colors.green;
                  statusIcon = Icons.wifi;
                  break;
                case ConnectionStatus.connecting:
                case ConnectionStatus.searching:
                  statusColor = Colors.orange;
                  statusIcon = Icons.wifi_find;
                  break;
                case ConnectionStatus.error:
                  statusColor = Colors.red;
                  statusIcon = Icons.wifi_off;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.wifi_off_outlined;
              }
              return IconButton(
                icon: Icon(statusIcon, color: statusColor),
                tooltip: 'Tambazotra (Réseau)',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NetworkConnectionView()),
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeProvider);
              final isDark = themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDark ? 'Mode clair' : 'Mode sombre',
                onPressed: () => ref.read(themeProvider.notifier).toggle(),
              );
            },
          ),
          const CastButtonWidget(),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(orderProvider.notifier).addMockOrder();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Kaomandy Vaovao',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 24),
                  Text(
                    'Tsy misy kaomandy',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune commande en cours',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(orderProvider.notifier).loadDemoOrders(),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text(
                      'Charger données de démo',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : Row(
        children: [
          Expanded(
            child: _KanbanColumn(
              title: 'HATAO',
              orders: aFaireOrders,
              status: OrderStatus.aFaire,
              headerColor: const Color(0xFFE64A19),
              swipeTarget: OrderStatus.enCours,
              swipeLabel: 'Démarrer',
              swipeIcon: Icons.play_arrow,
              swipeColor: const Color(0xFF0288D1),
            ),
          ),
          Expanded(
            child: _KanbanColumn(
              title: 'AM-PIKARAKARANA',
              orders: enCoursOrders,
              status: OrderStatus.enCours,
              headerColor: const Color(0xFF0288D1),
              swipeTarget: OrderStatus.fait,
              swipeLabel: 'Prêt',
              swipeIcon: Icons.check,
              swipeColor: const Color(0xFF388E3C),
            ),
          ),
          Expanded(
            child: _KanbanColumn(
              title: 'VITA',
              orders: faitOrders,
              status: OrderStatus.fait,
              headerColor: const Color(0xFF388E3C),
              swipeTarget: null,
              swipeLabel: 'Archiver',
              swipeIcon: Icons.archive,
              swipeColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends ConsumerStatefulWidget {
  final String title;
  final List<OrderModel> orders;
  final OrderStatus status;
  final Color headerColor;
  final OrderStatus? swipeTarget;
  final String swipeLabel;
  final IconData swipeIcon;
  final Color swipeColor;

  const _KanbanColumn({
    required this.title,
    required this.orders,
    required this.status,
    required this.headerColor,
    required this.swipeTarget,
    required this.swipeLabel,
    required this.swipeIcon,
    required this.swipeColor,
  });

  @override
  ConsumerState<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<_KanbanColumn> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<OrderModel>(
      onWillAcceptWithDetails: (details) =>
          details.data.status != widget.status,
      onAcceptWithDetails: (details) {
        final order = details.data;
        ref.read(orderProvider.notifier).moveOrder(order.id, widget.status);
        final network = ref.read(networkClientProvider);
        if (network.isConnected) {
          network.sendUpdateStatus(order.id, widget.status);
        }
        setState(() {
          _isDraggingOver = false;
        });
      },
      onLeave: (data) {
        setState(() {
          _isDraggingOver = false;
        });
      },
      onMove: (details) {
        setState(() {
          _isDraggingOver = true;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDraggingOver
                ? widget.headerColor.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDraggingOver
                  ? widget.headerColor
                  : Theme.of(context).colorScheme.outlineVariant,
              width: _isDraggingOver ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: widget.headerColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.headerColor.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.headerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.orders.length}',
                        style: GoogleFonts.outfit(
                          color: widget.headerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.orders.length,
                  itemBuilder: (context, index) {
                    final order = widget.orders[index];
                    return _OrderCard(
                      order: order,
                      columnStatus: widget.status,
                      swipeTarget: widget.swipeTarget,
                      swipeLabel: widget.swipeLabel,
                      swipeIcon: widget.swipeIcon,
                      swipeColor: widget.swipeColor,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final OrderStatus columnStatus;
  final OrderStatus? swipeTarget;
  final String swipeLabel;
  final IconData swipeIcon;
  final Color swipeColor;

  const _OrderCard({
    required this.order,
    required this.columnStatus,
    required this.swipeTarget,
    required this.swipeLabel,
    required this.swipeIcon,
    required this.swipeColor,
  });

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = widget.order.elapsed;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = widget.order.elapsed;
        });
      }
    });
  }

  @override
  void didUpdateWidget(_OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _elapsed = widget.order.elapsed;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getTimerColor(Duration d) {
    if (d.inMinutes > 20) return const Color(0xFFD32F2F);
    if (d.inMinutes > 10) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _getTimerColor(_elapsed);

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(context, widget.order),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: timerColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: timerColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.order.tableNumber,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: timerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: timerColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: timerColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_elapsed),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: timerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...widget.order.items.map(_buildItemRow),
              ],
            ),
          ),
        ),
      ),
    );

    final draggable = Draggable<OrderModel>(
      data: widget.order,
      feedback: Transform.rotate(
        angle: 0.05,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width / 3.5,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE64A19),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.order.tableNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.order.items.take(3).map((item) => Text(
                      '${item.quantity}x ${item.name}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.none,
                        fontSize: 13,
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      child: _buildDismissible(cardContent),
    );

    return draggable;
  }

  Widget _buildDismissible(Widget child) {
    if (widget.swipeTarget != null) {
      return Dismissible(
        key: ValueKey('swipe_${widget.order.id}'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) {
          ref.read(orderProvider.notifier).moveOrder(
                widget.order.id,
                widget.swipeTarget!,
              );
          final network = ref.read(networkClientProvider);
          if (network.isConnected) {
            network.sendUpdateStatus(widget.order.id, widget.swipeTarget!);
          }
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.swipeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: Icon(widget.swipeIcon, color: Colors.white, size: 32),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.swipeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Icon(widget.swipeIcon, color: Colors.white, size: 32),
        ),
        child: child,
      );
    }

    return Dismissible(
      key: ValueKey('swipe_archive_${widget.order.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        ref.read(orderProvider.notifier).removeOrder(widget.order.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.archive, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.archive, color: Colors.white, size: 32),
      ),
      child: child,
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.quantity}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF5722),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.notes!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFF5722),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Mombamomba ny kaomandy',
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return _OrderDetailsDialog(order: order);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }
}

class _OrderDetailsDialog extends StatefulWidget {
  final OrderModel order;

  const _OrderDetailsDialog({required this.order});

  @override
  State<_OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<_OrderDetailsDialog> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = widget.order.elapsed;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = widget.order.elapsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getTimerColor(Duration d) {
    if (d.inMinutes > 20) return const Color(0xFFD32F2F);
    if (d.inMinutes > 10) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.order.tableNumber,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTimerColor(_elapsed).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTimerColor(_elapsed),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                size: 16,
                                color: _getTimerColor(_elapsed),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(_elapsed),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getTimerColor(_elapsed),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Voaray tamin'ny ${widget.order.createdAt.hour.toString().padLeft(2, '0')}:${widget.order.createdAt.minute.toString().padLeft(2, '0')}",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.order.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.order.items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5722),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'x${item.quantity}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                          item.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                    ),
                                  ],
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Color(0xFFFF5722),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.notes!,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                              color: const Color(0xFFFF5722),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Hidio',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
