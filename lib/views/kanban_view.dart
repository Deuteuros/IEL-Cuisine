import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/network_provider.dart';
import '../services/network_client_service.dart';
import 'network_connection_view.dart';

class KanbanView extends ConsumerWidget {
  const KanbanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);

    final aFaireOrders = orders.where((o) => o.status == OrderStatus.aFaire).toList();
    final enCoursOrders = orders.where((o) => o.status == OrderStatus.enCours).toList();
    final faitOrders = orders.where((o) => o.status == OrderStatus.fait).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE64A19).withOpacity(0.2),
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
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Network status icon
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
      body: Row(
        children: [
          Expanded(
            child: _KanbanColumn(
              title: 'HATAO',
              orders: aFaireOrders,
              status: OrderStatus.aFaire,
              headerColor: const Color(0xFFE64A19),
            ),
          ),
          Expanded(
            child: _KanbanColumn(
              title: 'AM-PIKARAKARANA',
              orders: enCoursOrders,
              status: OrderStatus.enCours,
              headerColor: const Color(0xFF0288D1),
            ),
          ),
          Expanded(
            child: _KanbanColumn(
              title: 'VITA',
              orders: faitOrders,
              status: OrderStatus.fait,
              headerColor: const Color(0xFF388E3C),
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

  const _KanbanColumn({
    required this.title,
    required this.orders,
    required this.status,
    required this.headerColor,
  });

  @override
  ConsumerState<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<_KanbanColumn> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<OrderModel>(
      onWillAccept: (data) => data != null && data.status != widget.status,
      onAccept: (data) {
        ref.read(orderProvider.notifier).moveOrder(data.id, widget.status);
        // Send UPDATE_STATUS via WebSocket if connected
        final network = ref.read(networkClientProvider);
        if (network.isConnected) {
          network.sendUpdateStatus(data.id, widget.status);
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
      onMove: (data) {
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
                ? widget.headerColor.withOpacity(0.08)
                : const Color(0xFF16161E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDraggingOver
                  ? widget.headerColor
                  : const Color(0xFF2C2C35),
              width: _isDraggingOver ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              // Column Header
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
                                color: widget.headerColor.withOpacity(0.6),
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
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.headerColor.withOpacity(0.2),
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
              const Divider(color: Color(0xFF2C2C35), height: 1),
              // List of Orders
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.orders.length,
                  itemBuilder: (context, index) {
                    final order = widget.orders[index];
                    return _OrderCard(order: order);
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

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(context, order),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF252530),
                  const Color(0xFF1E1E26),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF353545),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                order.tableNumber,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Draggable<OrderModel>(
      data: order,
      feedback: Transform.rotate(
        angle: 0.05,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width / 3.5,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C3C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE64A19),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                order.tableNumber,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardWidget,
      ),
      child: cardWidget,
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Mombamomba ny kaomandy',
      barrierColor: Colors.black.withOpacity(0.7),
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
    if (d.inMinutes > 20) return const Color(0xFFD32F2F); // Red
    if (d.inMinutes > 10) return const Color(0xFFF57C00); // Orange
    return const Color(0xFF388E3C); // Green
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF353545),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
                    // Title and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.order.tableNumber,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTimerColor(_elapsed).withOpacity(0.2),
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
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF353545), height: 1),
                    const SizedBox(height: 16),
                    // Item List
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.order.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.order.items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252530),
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
                                          color: Colors.white,
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
                                      color: const Color(0xFFFF5722).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFF5722).withOpacity(0.3),
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
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Hidio',
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
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
