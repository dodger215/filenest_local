import 'package:flutter/material.dart';
import '../../config/backend_config.dart';
import '../../state/drive_ui_controller.dart';

class BackendSettingsSection extends StatefulWidget {
  final DriveUiController controller;
  const BackendSettingsSection({super.key, required this.controller});
  @override
  State<BackendSettingsSection> createState() => _BackendSettingsSectionState();
}

class _BackendSettingsSectionState extends State<BackendSettingsSection> {
  late final url = TextEditingController(
    text: widget.controller.connection.baseUrl,
  );
  bool busy = false;
  String? message;
  bool failed = false;
  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  Future<void> run(bool save) async {
    setState(() {
      busy = true;
      message = null;
      failed = false;
    });
    try {
      if (save) {
        await widget.controller.setBackendUrl(url.text);
        url.text = widget.controller.connection.baseUrl;
      } else {
        await widget.controller.testBackendUrl(url.text);
      }
      if (mounted)
        setState(
          () => message = save
              ? 'Backend URL saved on this device.'
              : 'Connected to FileNest successfully.',
        );
    } catch (e) {
      if (mounted)
        setState(() {
          failed = true;
          message = DriveUiController.friendlyError(e);
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backend server', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            'Enter the server URL, including its port. Devices on the same network use the server machine’s LAN IP.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: url,
            enabled: !busy && !widget.controller.transfersRunning,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Backend URL',
              hintText: 'http://192.168.1.10:3001',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: busy || widget.controller.transfersRunning
                    ? null
                    : () => run(true),
                child: Text(busy ? 'Working…' : 'Save URL'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => run(false),
                child: const Text('Test connection'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => url.text = BackendConfig.defaultUrl),
                child: const Text('Use build default'),
              ),
            ],
          ),
          if (message != null)
            Text(
              message!,
              style: TextStyle(
                color: failed ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          if (widget.controller.transfersRunning)
            const Text('Wait for transfers to finish before changing servers.'),
        ],
      ),
    ),
  );
}
