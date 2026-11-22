import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';

/// 20 second waiting screen. Connects to the server in the background and
/// opens the app when BOTH the 20 seconds are over and the connection is ready.
class SplashPage extends StatefulWidget {
  final WidgetBuilder next;
  const SplashPage({super.key, required this.next});
  @override
  State<SplashPage> createState() => _SplashState();
}

class _SplashState extends State<SplashPage> with SingleTickerProviderStateMixin {
  static const int total = 20; // seconds
  static const _steps = [
    'Connecting to server...',
    'Checking your account...',
    'Loading your wallet...',
    'Preparing rewards...',
    'Almost ready...',
  ];
  static const _tips = [
    'Invite friends and earn referral coins',
    'Scratch and spin every day for free coins',
    'VIP members can earn automatically with ads',
    'Withdraw once you reach the minimum limit',
  ];

  late final AnimationController _ctl = AnimationController(vsync: this, duration: const Duration(seconds: total));
  bool _initDone = false, _timeDone = false, _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _timeDone = true;
        _check();
      }
    });
    _ctl.forward();
    _init();
  }

  Future<void> _init() async {
    try {
      await initApi().timeout(const Duration(seconds: 20));
      _initDone = true;
      _error = null;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() {});
    _check();
  }

  void _check() {
    if (mounted && _initDone && _timeDone && !_ready) setState(() => _ready = true);
  }

  void _retry() {
    setState(() => _error = null);
    _init();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.next(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B1FBF), kBrand, kBrand2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            child: AnimatedBuilder(
              animation: _ctl,
              builder: (context, _) {
                final v = _ctl.value;
                final left = (total - v * total).ceil().clamp(0, total).toInt();
                final step = math.min((v * _steps.length).floor(), _steps.length - 1);
                final tip = (v * total / 5).floor() % _tips.length;
                return Column(children: [
                  const Spacer(flex: 3),
                  Transform.scale(
                    scale: 1 + 0.06 * math.sin(v * total * 2.2),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)]),
                      child: const Icon(Icons.account_balance_wallet_rounded, size: 72, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Earn Rewards', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Scratch  •  Spin  •  Watch  •  Earn', style: TextStyle(color: Colors.white70, letterSpacing: 1)),
                  const Spacer(flex: 3),
                  if (_error != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          const Icon(Icons.cloud_off, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text('Could not connect:\n$_error', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                        ]),
                      ),
                    ),
                  ] else ...[
                    Text(_steps[step], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('${(v * 100).round()}%   •   Starting in $left s', style: const TextStyle(color: Colors.white70)),
                  ],
                  const SizedBox(height: 26),
                  Text('Tip: ${_tips[tip]}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
