import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/ui.dart';
import 'earn_pages.dart';

const _gold = [Color(0xFFFFB020), Color(0xFFFF7A45)];

class VipPage extends StatefulWidget {
  const VipPage({super.key});
  @override
  State<VipPage> createState() => _V();
}

class _V extends State<VipPage> {
  final utr = TextEditingController(); bool busy = false;
  Future<void> submit() async {
    setState(() => busy = true);
    try {
      await call('submitVipPayment', {'utr': utr.text});
      utr.clear();
      if (mounted) toast(context, 'Submitted. Waiting for admin approval.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget step(BuildContext c, String n, String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
        CircleAvatar(radius: 13, backgroundColor: kBrand.withValues(alpha: 0.15), child: Text(n, style: const TextStyle(color: kBrand, fontWeight: FontWeight.w800, fontSize: 12))),
        const SizedBox(width: 12), Expanded(child: Text(t)),
      ]));

  @override
  Widget build(BuildContext c) => StreamBuilder<Map<String, dynamic>>(stream: docStream('users/$uid'), builder: (c, us) =>
    StreamBuilder<Map<String, dynamic>>(stream: docStream('app_settings/main'), builder: (c, cs) {
      if (!us.hasData || !cs.hasData) return const Scaffold(body: Loading());
      final u = us.data!, cfg = cs.data!;
      if (u['vip'] == true) {
        final exp = dt(u['vipExpiry']);
        final since = fmtDt(u['vipSince'], 10);
        return Scaffold(appBar: AppBar(title: const Text('VIP')), body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
          GradientCard(colors: _gold, child: Column(children: [
            Container(padding: const EdgeInsets.all(18), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.workspace_premium, size: 52, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('VIP Active', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Since ${since.isEmpty ? '-' : since}${exp != null ? '  •  Expires ${exp.toString().substring(0, 10)}' : ''}', style: const TextStyle(color: Colors.white70)),
          ])),
          const SizedBox(height: 18),
          if (cfg['vipEarnEnabled'] != false)
            FilledButton.icon(icon: const Icon(Icons.play_arrow), label: const Text('Open VIP Earning'),
                onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => AdsPage(config: cfg, vip: true)))),
        ]));
      }
      return Scaffold(appBar: AppBar(title: const Text('Become VIP')), body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        GradientCard(colors: _gold, child: Row(children: [
          Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.workspace_premium, size: 36, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Unlock VIP earning', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            Text('One-time price ${money(cfg['vipPrice'] ?? 50)}', style: const TextStyle(color: Colors.white70)),
          ])),
        ])),
        const SectionTitle('How it works'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          step(c, '1', 'Pay the amount using the QR code or UPI ID'),
          step(c, '2', 'Enter the UTR / transaction ID below'),
          step(c, '3', 'Admin verifies and activates your VIP'),
        ]))),
        if ((cfg['vipQrUrl'] ?? '') != '')
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(16),
              child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.network('${cfg['vipQrUrl']}', height: 220)))))),
        if ((cfg['vipUpiId'] ?? '') != '')
          Card(child: ListTile(leading: const Icon(Icons.account_balance, color: kBrand), title: Text('${cfg['vipUpiId']}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('UPI ID'),
              trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: '${cfg['vipUpiId']}')); toast(c, 'UPI ID copied'); }))),
        const SizedBox(height: 10),
        TextField(controller: utr, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'UTR / Transaction ID', prefixIcon: Icon(Icons.receipt_long))),
        const SizedBox(height: 14),
        FilledButton.icon(icon: const Icon(Icons.send), onPressed: busy ? null : submit, label: const Text('Submit payment')),
        const SectionTitle('Your requests'),
        StreamBuilder<List<Map<String, dynamic>>>(stream: listStream('vip_payment_requests', filter: 'user = "$uid"', sort: '-created', limit: 20), builder: (c, s) {
          final d = s.data ?? <Map<String, dynamic>>[];
          if (d.isEmpty) return const Empty('No requests yet');
          return Column(children: [for (final m in d)
            Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text('${m['utr']}'), subtitle: Text(fmtDt(m['created'])), trailing: StatusChip('${m['status']}')))]);
        }),
      ]));
    }));
}
