import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';

/// Shown when the app cannot load its settings from the server. Runs a test and says what is wrong.
class ConnectionProblem extends StatefulWidget {
  final Object? error;
  final VoidCallback onRetry;
  const ConnectionProblem({super.key, required this.error, required this.onRetry});
  @override
  State<ConnectionProblem> createState() => _ConnectionProblemState();
}

class _ConnectionProblemState extends State<ConnectionProblem> {
  String? report;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _test();
  }

  Future<void> _test() async {
    setState(() {
      busy = true;
      report = null;
    });
    final r = await diagnose();
    if (mounted) {
      setState(() {
        report = r;
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: kBrand.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.cloud_off, size: 48, color: kBrand),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Cannot connect to the server', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: busy
                    ? const Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Testing the connection...')])
                    : SelectableText(report ?? '${widget.error}'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: widget.onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: busy ? null : _test, icon: const Icon(Icons.network_check), label: const Text('Run test again')),
          ]),
        ),
      );
}
