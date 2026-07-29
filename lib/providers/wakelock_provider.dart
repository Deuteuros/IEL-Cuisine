import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final wakelockProvider = Provider<void>((ref) {
  WakelockPlus.enable();
  ref.onDispose(() => WakelockPlus.disable());
});
