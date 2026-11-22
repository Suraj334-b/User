import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/ads_service.dart';
import 'core/api.dart';
import 'core/ui.dart';
import 'presentation/connection_problem.dart';
import 'presentation/login_page.dart';
import 'presentation/shell.dart';
import 'presentation/splash_page.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const EarningApp());
    unawaited(AdsService.instance.init()); // background: ads can never stop the app from opening
  }, (e, st) => debugPrint('Uncaught: $e'));
}

class EarningApp extends StatelessWidget {
  const EarningApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Earning App',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: SplashPage(next: (_) => const Gate()),
      );
}

int _v(String s) {
  final p = s.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  while (p.length < 3) { p.add(0); }
  return p[0] * 1000000 + p[1] * 1000 + p[2];
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  Stream<Map<String, dynamic>> _settings = docStream('app_settings/main');

  void _retry() => setState(() => _settings = docStream('app_settings/main'));

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
        stream: _settings,
        builder: (c, s) {
          if (s.hasError) return ConnectionProblem(error: s.error, onRetry: _retry);
          if (!s.hasData) return const Scaffold(body: Loading());
          final cfg = s.data!;
          coinRate = ((cfg['coinsPerRupee'] ?? 100) as num).toDouble();
          if (coinRate <= 0) coinRate = 100;
          if (cfg['maintenance'] == true) {
            return Scaffold(body: Empty('${cfg['maintenanceMessage'] ?? 'Under maintenance. Please come back soon.'}', icon: Icons.build_circle_outlined));
          }
          return FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (c, p) {
              if (!p.hasData) return const Scaffold(body: Loading());
              final minV = '${cfg['minVersion'] ?? ''}';
              if (minV.isNotEmpty && _v(p.data!.version) < _v(minV)) {
                return const Scaffold(body: Empty('Please update the app to continue.', icon: Icons.system_update));
              }
              return StreamBuilder<dynamic>(
                stream: pb.authStore.onChange,
                builder: (c, a) => pb.authStore.isValid ? Shell(config: cfg) : const LoginPage(),
              );
            },
          );
        },
      );
}
