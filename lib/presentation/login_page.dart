import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _S();
}

class _S extends State<LoginPage> {
  final ref = TextEditingController();
  bool busy = false;

  Future<void> login() async {
    setState(() => busy = true);
    try {
      await loginWithGoogle(ref.text.trim());
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B1FBF), kBrand, kBrand2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
            const Spacer(),
            Container(padding: const EdgeInsets.all(22), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 64, color: Colors.white)),
            const SizedBox(height: 18),
            const Text('Earn Rewards', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Scratch, spin and watch to earn real rewards', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const Spacer(),
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              TextField(controller: ref, textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Referral code (optional)', prefixIcon: Icon(Icons.card_giftcard))),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: busy ? null : login,
                  icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                  label: const Text('Continue with Google'))),
            ]))),
          ]))),
        ),
      );
}
