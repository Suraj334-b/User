import 'package:flutter/material.dart';

const kBrand = Color(0xFF6C4DFF);
const kBrand2 = Color(0xFFB04DFF);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: kBrand, brightness: b);
  final surface = dark ? const Color(0xFF1A1A2E) : Colors.white;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0F0E17) : const Color(0xFFF6F5FF),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0, color: surface, margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68, backgroundColor: dark ? const Color(0xFF15142A) : Colors.white,
      indicatorColor: kBrand.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true, fillColor: dark ? const Color(0xFF23233B) : const Color(0xFFF0EEFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBrand, width: 1.6)),
    ),
  );
}

void toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));

class GradientCard extends StatelessWidget {
  final Widget child; final List<Color> colors; final EdgeInsets padding;
  const GradientCard({super.key, required this.child, this.colors = const [kBrand, kBrand2], this.padding = const EdgeInsets.all(22)});
  @override
  Widget build(BuildContext c) => Container(
      width: double.infinity, padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))]),
      child: child);
}

class Empty extends StatelessWidget {
  final String text; final IconData icon;
  const Empty(this.text, {super.key, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext c) => Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kBrand.withValues(alpha: 0.10), shape: BoxShape.circle), child: Icon(icon, size: 40, color: kBrand)),
        const SizedBox(height: 12), Text(text, textAlign: TextAlign.center)])));
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext c) => const Center(child: CircularProgressIndicator());
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(text, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)));
}

class StatCard extends StatelessWidget {
  final String label, value; final IconData icon;
  const StatCard(this.label, this.value, this.icon, {super.key});
  @override
  Widget build(BuildContext c) => Expanded(child: Card(
      margin: const EdgeInsets.all(5),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kBrand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: kBrand)),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
        Text(label, style: Theme.of(c).textTheme.bodySmall)]))));
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext c) {
    final col = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Text(status.toUpperCase(), style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 11)));
  }
}

/// Coins per 1 rupee (set from admin settings in Gate).
double coinRate = 100;
String _group(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
/// Wallet values are stored in rupees; the app shows them as coins.
String fmtCoins(num? rupees) => _group(((rupees ?? 0) * coinRate).round());
String coins(num? rupees) => '${fmtCoins(rupees)} coins';

String money(num? v) => '₹${(v ?? 0).toStringAsFixed(2)}';
