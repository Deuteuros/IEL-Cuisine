import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_provider.dart';
import '../services/network_client_service.dart';

class NetworkConnectionView extends ConsumerStatefulWidget {
  const NetworkConnectionView({super.key});

  @override
  ConsumerState<NetworkConnectionView> createState() => _NetworkConnectionViewState();
}

class _NetworkConnectionViewState extends ConsumerState<NetworkConnectionView> {
  final _ipController = TextEditingController(text: '192.168.');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final network = ref.read(networkClientProvider);
    network.startMdnsDiscovery();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkClient = ref.watch(networkClientProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        title: const Text(
          'Tambazotra (Réseau)',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _StatusCard(client: networkClient),
          const SizedBox(height: 32),

          if (networkClient.discoveredServers.isNotEmpty) ...[
            const Text(
              "Serveurs détectés sur le réseau",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...networkClient.discoveredServers.map((server) => _DiscoveredServerTile(
              server: server,
              isConnected: networkClient.serverUrl?.contains(server.ip) == true,
              onTap: () => ref.read(networkClientProvider).connect(server.ip, port: server.port),
            )),
            const SizedBox(height: 32),
          ],

          const Text(
            "Adiresy IP an'ny CaisseCash",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _ipController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ex: 192.168.1.100',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.wifi_outlined, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF353545)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF353545)),
                ),
                filled: true,
                fillColor: const Color(0xFF16161E),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Mila adiresy IP';
                final parts = value.trim().split('.');
                if (parts.length != 4) return 'Format IP tsy mety (ex: 192.168.1.100)';
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          if (networkClient.status == ConnectionStatus.disconnected ||
              networkClient.status == ConnectionStatus.error)
            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ref.read(networkClientProvider).connect(_ipController.text.trim());
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Mifandray (Connecter)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

          if (networkClient.status == ConnectionStatus.connecting)
            const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722))),

          if (networkClient.status == ConnectionStatus.connected)
            OutlinedButton.icon(
              onPressed: () => ref.read(networkClientProvider).disconnect(),
              icon: const Icon(Icons.link_off),
              label: const Text('Sasaka ny fifandraisana (Déconnecter)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

          if (networkClient.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              networkClient.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscoveredServerTile extends StatelessWidget {
  final DiscoveredServer server;
  final bool isConnected;
  final VoidCallback onTap;

  const _DiscoveredServerTile({
    required this.server,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.08)
            : const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? Colors.green.withValues(alpha: 0.3)
              : const Color(0xFF353545),
        ),
      ),
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.wifi : Icons.wifi_find,
          color: isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(
          server.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${server.ip}:${server.port}',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.grey.shade400,
          ),
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(
                onPressed: onTap,
                child: const Text(
                  'Connecter',
                  style: TextStyle(color: Color(0xFFFF5722)),
                ),
              ),
        onTap: isConnected ? null : onTap,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final NetworkClientService client;
  const _StatusCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (client.status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.wifi;
        statusText = "Mifandray amin'ny serveur";
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_find;
        statusText = 'Mikairy fifandraisana…';
        break;
      case ConnectionStatus.searching:
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_find;
        statusText = 'Mitady serveur…';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.redAccent;
        statusIcon = Icons.wifi_off;
        statusText = 'Fahadisoana fifandraisana';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.wifi_off_outlined;
        statusText = 'Tsy mifandray';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 16,
                  ),
                ),
                if (client.serverUrl != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    client.serverUrl!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (client.status == ConnectionStatus.searching ||
              client.status == ConnectionStatus.connecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }
}
