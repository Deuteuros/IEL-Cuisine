import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class CastKanbanReceiver extends ConsumerStatefulWidget {
  const CastKanbanReceiver({super.key});

  @override
  ConsumerState<CastKanbanReceiver> createState() => _CastKanbanReceiverState();
}

class _CastKanbanReceiverState extends ConsumerState<CastKanbanReceiver> {
  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderProvider);

    final aFaire = orders.where((o) => o.status == OrderStatus.aFaire).toList();
    final enCours = orders.where((o) => o.status == OrderStatus.enCours).toList();
    final fait = orders.where((o) => o.status == OrderStatus.fait).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu,
                    color: Colors.white.withValues(alpha: 0.6), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'LAKOZIA — CUISINE',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _CastColumn(
                    title: 'HATAO',
                    orders: aFaire,
                    color: const Color(0xFFE64A19),
                  )),
                  Expanded(child: _CastColumn(
                    title: 'AM-PIKARAKARANA',
                    orders: enCours,
                    color: const Color(0xFF0288D1),
                  )),
                  Expanded(child: _CastColumn(
                    title: 'VITA',
                    orders: fait,
                    color: const Color(0xFF388E3C),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastColumn extends StatelessWidget {
  final String title;
  final List<OrderModel> orders;
  final Color color;

  const _CastColumn({
    required this.title,
    required this.orders,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C35)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: GoogleFonts.outfit(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2C2C35), height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _CastOrderCard(order: order, accentColor: color);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CastOrderCard extends StatefulWidget {
  final OrderModel order;
  final Color accentColor;

  const _CastOrderCard({required this.order, required this.accentColor});

  @override
  State<_CastOrderCard> createState() => _CastOrderCardState();
}

class _CastOrderCardState extends State<_CastOrderCard> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = widget.order.elapsed;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = widget.order.elapsed);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color _getTimerColor(Duration d) {
    if (d.inMinutes > 20) return const Color(0xFFD32F2F);
    if (d.inMinutes > 10) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _getTimerColor(_elapsed);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252530),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timerColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.order.tableNumber,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: timerColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: timerColor),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_elapsed),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.order.items.map(_buildItemRow),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFF5722),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
