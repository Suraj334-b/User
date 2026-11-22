import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api.dart';
import '../core/ui.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> config;
  const HomePage({super.key, required this.config});
  @override
  Widget build(BuildContext c) {
    final sections = List<String>.from(config['homeSections'] ?? ['announcement', 'banners', 'recent']);
    return Scaffold(
      appBar: AppBar(title: Text(config['appName'] ?? 'Earning App'), actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
        IconButton(icon: const Icon(Icons.logout), onPressed: () => logout())]),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: docStream('users/$uid'),
        builder: (c, us) => StreamBuilder<Map<String, dynamic>>(
          stream: docStream('wallets/$uid'),
          builder: (c, ws) {
            if (!us.hasData || !ws.hasData) return const Loading();
            final u = us.data!, w = ws.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              Row(children: [
                CircleAvatar(radius: 24, backgroundColor: kBrand.withValues(alpha: 0.15),
                    backgroundImage: (u['photoUrl'] ?? '') != '' ? NetworkImage('${u['photoUrl']}') : null,
                    child: (u['photoUrl'] ?? '') == '' ? const Icon(Icons.person, color: kBrand) : null),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back', style: Theme.of(c).textTheme.bodySmall),
                  Text('${u['displayName'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ])),
                Text('ID ${(uid.length >= 8 ? uid.substring(0, 8) : uid)}', style: Theme.of(c).textTheme.bodySmall),
              ]),
              const SizedBox(height: 16),
              GradientCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Coin balance', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(u['vip'] == true ? '👑 VIP' : 'FREE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                ]),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Icon(Icons.toll, color: Color(0xFFFFD66B), size: 34), const SizedBox(width: 8),
                  Text(fmtCoins(w['balance']), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                ]),
                Text('≈ ${money(w['balance'])}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Pending', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(coins(w['pending']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Referral earned', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(coins(w['referralEarned']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))])),
                ]),
              ])),
              const SizedBox(height: 10),
              Row(children: [
                StreamBuilder<Map<String, dynamic>>(stream: docStream('users/$uid/daily/${today()}'),
                    builder: (c, d) {
                      final m = d.data ?? {};
                      final n = ((m['scratch'] ?? 0) as num) + (m['spin'] ?? 0) + (m['ads'] ?? 0) + (m['vipAds'] ?? 0);
                      return StatCard('Actions today', '$n', Icons.today);
                    }),
                StatCard('Lifetime earned', coins(w['totalEarned']), Icons.trending_up),
              ]),
              const SizedBox(height: 8),
              for (final s in sections) ...[
                if (s == 'announcement' && (config['announcement'] ?? '') != '')
                  Card(child: ListTile(leading: const Icon(Icons.campaign), title: Text(config['announcement']))),
                if (s == 'banners') const _Banners(),
                if (s == 'recent') ...[
                  const SectionTitle('Recent transactions'),
                  const TxList(limit: 5),
                ],
              ],
              const SizedBox(height: 12), FilledButton.icon(icon: const Icon(Icons.share), label: const Text('Invite & earn'),
                  onPressed: () => Share.share('Join and earn! Use my code ${u['referralCode']}')),
            ]);
          },
        ),
      ),
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners();
  @override
  Widget build(BuildContext c) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: listStream('banners', filter: 'active = true', sort: '-created', limit: 20),
        builder: (c, s) {
          final docs = s.data ?? [];
          if (docs.isEmpty) return const SizedBox();
          return SizedBox(height: 140, child: PageView(children: [
            for (final d in docs)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ClipRRect(borderRadius: BorderRadius.circular(18),
                  child: Image.network('${d['imageUrl'] ?? ''}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())))]));
        });
}

class TxList extends StatelessWidget {
  final int? limit;
  const TxList({super.key, this.limit});
  @override
  Widget build(BuildContext c) => StreamBuilder<List<Map<String, dynamic>>>(
      stream: listStream('transactions', filter: 'user = "$uid"', sort: '-created', limit: limit ?? 100),
      builder: (c, s) {
        if (!s.hasData) return const Loading();
        if (s.data!.isEmpty) return const Empty('No transactions yet');
        return ListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
          for (final m in s.data!)
            Builder(builder: (_) {
              final a = (m['amount'] as num).toDouble();
              return ListTile(dense: true,
                  leading: Icon(a >= 0 ? Icons.south_west : Icons.north_east, color: a >= 0 ? Colors.green : Colors.red),
                  title: Text(m['type'].toString().replaceAll('_', ' ')),
                  subtitle: Text(fmtDt(m['created'])),
                  trailing: Text('${a >= 0 ? '+' : ''}${fmtCoins(a)}', style: TextStyle(color: a >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)));
            })]);
      });
}

/// In-app notifications (sent from the admin panel).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: listStream('notifications', sort: '-created', limit: 50),
          builder: (c, s) {
            if (!s.hasData) return const Loading();
            if (s.data!.isEmpty) return const Empty('No notifications', icon: Icons.notifications_none);
            return ListView(children: [
              for (final m in s.data!)
                ListTile(leading: const Icon(Icons.campaign_outlined), title: Text('${m['title']}'), subtitle: Text('${m['body']}\n${fmtDt(m['created'])}'), isThreeLine: true)
            ]);
          },
        ),
      );
}
