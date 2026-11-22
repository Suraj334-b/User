import 'package:flutter/material.dart';
import 'earn_pages.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'vip_pages.dart';
import 'wallet_page.dart';

class Shell extends StatefulWidget {
  final Map<String, dynamic> config;
  const Shell({super.key, required this.config});
  @override
  State<Shell> createState() => _S();
}

class _S extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext c) {
    final pages = [HomePage(config: widget.config), EarnPage(config: widget.config), const VipPage(), const WalletPage(), ProfilePage(config: widget.config)];
    return Scaffold(
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(i), child: pages[i])),
      bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Earn'),
        NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium), label: 'VIP'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ]),
    );
  }
}
