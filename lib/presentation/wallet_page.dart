import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api.dart';
import '../core/ui.dart';
import 'home_page.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext c) => DefaultTabController(length: 3, child: Scaffold(
    appBar: AppBar(title: const Text('Wallet'), bottom: const TabBar(dividerColor: Colors.transparent, tabs: [Tab(text: 'Balance'), Tab(text: 'Withdraw'), Tab(text: 'Refer')])),
    body: const TabBarView(children: [_Balance(), WithdrawTab(), ReferTab()])));
}

class _Balance extends StatelessWidget {
  const _Balance();
  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
    StreamBuilder<Map<String, dynamic>>(stream: docStream('wallets/$uid'), builder: (c, s) {
      final w = s.data ?? {};
      return Column(children: [
        GradientCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Coin balance', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.toll, color: Color(0xFFFFD66B), size: 34), const SizedBox(width: 8),
            Text(fmtCoins(w['balance']), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
          ]),
          Text('≈ ${money(w['balance'])}  •  ${coinRate.round()} coins = ₹1', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.hourglass_bottom, size: 16, color: Colors.white70), const SizedBox(width: 6), Text('Pending ${coins(w['pending'])}', style: const TextStyle(color: Colors.white70))]),
        ])),
        const SizedBox(height: 8),
        Row(children: [StatCard('Total earned', coins(w['totalEarned']), Icons.trending_up), StatCard('Referral', coins(w['referralEarned']), Icons.group)]),
        Row(children: [StatCard('VIP earnings', coins(w['vipEarned']), Icons.workspace_premium), const Spacer()]),
      ]);
    }),
    const SectionTitle('Transactions'), const TxList(),
  ]);
}

class WithdrawTab extends StatefulWidget {
  const WithdrawTab({super.key});
  @override
  State<WithdrawTab> createState() => _W();
}

class _W extends State<WithdrawTab> {
  final amt = TextEditingController(), det = TextEditingController();
  String method = 'UPI'; bool busy = false;
  Future<void> go() async {
    setState(() => busy = true);
    try {
      await call('requestWithdrawal', {'amount': double.parse(((double.tryParse(amt.text) ?? 0) / coinRate).toStringAsFixed(2)), 'method': method, 'details': det.text});
      amt.clear(); det.clear();
      if (mounted) toast(context, 'Withdrawal requested');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext c) => StreamBuilder<Map<String, dynamic>>(stream: docStream('app_settings/main'), builder: (c, s) {
    final cfg = s.data ?? {};
    final methods = List<String>.from(cfg['withdrawMethods'] ?? ['UPI']);
    if (!methods.contains(method)) method = methods.first;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.info_outline, size: 18, color: kBrand), const SizedBox(width: 8), Text('Minimum withdrawal ${coins(cfg['minWithdraw'] ?? 50)} (${money(cfg['minWithdraw'] ?? 50)})')]),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(initialValue: method, items: [for (final m in methods) DropdownMenuItem(value: m, child: Text(m))], onChanged: (v) => method = v!, decoration: const InputDecoration(labelText: 'Method')),
        const SizedBox(height: 12), TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (coins)', prefixIcon: Icon(Icons.toll))),
        const SizedBox(height: 12), TextField(controller: det, decoration: const InputDecoration(labelText: 'UPI ID / payment details', prefixIcon: Icon(Icons.account_balance_wallet))),
        const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton.icon(icon: const Icon(Icons.north_east), onPressed: busy ? null : go, label: const Text('Request withdrawal'))),
      ]))),
      const SectionTitle('History'),
      StreamBuilder<List<Map<String, dynamic>>>(stream: listStream('withdrawal_requests', filter: 'user = "$uid"', sort: '-created', limit: 50), builder: (c, h) {
        final d = h.data ?? <Map<String, dynamic>>[];
        if (d.isEmpty) return const Empty('No withdrawals yet');
        return Column(children: [for (final m in d)
          Card(child: ListTile(leading: const Icon(Icons.north_east), title: Text(coins(m['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${m['paymentRef'] ?? ''}'.isNotEmpty ? 'Ref: ${m['paymentRef']}' : '${money(m['amount'])} • ${m['method']} • ${fmtDt(m['created'])}'), trailing: StatusChip('${m['status']}')))]);
      }),
    ]);
  });
}

class ReferTab extends StatelessWidget {
  const ReferTab({super.key});
  @override
  Widget build(BuildContext c) => StreamBuilder<Map<String, dynamic>>(stream: docStream('users/$uid'), builder: (c, s) {
    final code = '${s.data?['referralCode'] ?? ''}';
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      GradientCard(colors: const [Color(0xFF2EC4B6), Color(0xFF4D8DFF)], child: Column(children: [
        const Icon(Icons.card_giftcard, size: 44, color: Colors.white),
        const SizedBox(height: 8),
        const Text('Invite friends and earn', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
            child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 4))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)), icon: const Icon(Icons.copy), label: const Text('Copy'),
              onPressed: () { Clipboard.setData(ClipboardData(text: code)); toast(c, 'Code copied'); })),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kBrand), icon: const Icon(Icons.share), label: const Text('Share'),
              onPressed: () => Share.share('Join and earn! Use my code $code'))),
        ]),
      ])),
      const SectionTitle('Referral history'),
      StreamBuilder<List<Map<String, dynamic>>>(stream: listStream('referrals', filter: 'referrer = "$uid"', sort: '-created', limit: 50), builder: (c, r) {
        final d = r.data ?? <Map<String, dynamic>>[];
        if (d.isEmpty) return const Empty('No referrals yet');
        return Column(children: [for (final m in d)
          Card(child: ListTile(leading: const Icon(Icons.person_add), title: Text(coins(m['bonus']), style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(fmtDt(m['created'])), trailing: StatusChip('${m['status']}')))]);
      }),
    ]);
  });
}
