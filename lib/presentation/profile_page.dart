import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../core/ui.dart';

Future<void> openUrl(BuildContext c, String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && c.mounted) toast(c, 'Could not open link');
  } catch (_) {
    if (c.mounted) toast(c, 'Could not open link');
  }
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> config;
  const ProfilePage({super.key, required this.config});

  String _s(String k) => '${config[k] ?? ''}'.trim();

  Widget _tile(IconData i, Color col, String title, String sub, VoidCallback onTap) => Card(
        child: ListTile(
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: col.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)), child: Icon(i, color: col)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: sub.isEmpty ? null : Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Widget _row(BuildContext c, IconData i, String label, String value, {bool copy = false}) => ListTile(
        dense: true,
        leading: Icon(i, size: 20, color: kBrand),
        title: Text(label, style: Theme.of(c).textTheme.bodySmall),
        subtitle: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: copy && value.isNotEmpty
            ? IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () { Clipboard.setData(ClipboardData(text: value)); toast(c, 'Copied'); })
            : null,
      );

  @override
  Widget build(BuildContext c) {
    final email = _s('supportEmail'), wa = _s('supportWhatsapp').replaceAll(RegExp(r'[^0-9]'), ''), link = _s('supportLink'), hours = _s('supportHours');
    final hasSupport = email.isNotEmpty || wa.isNotEmpty || link.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: docStream('users/$uid'),
        builder: (c, us) => StreamBuilder<Map<String, dynamic>>(
          stream: docStream('wallets/$uid'),
          builder: (c, ws) {
            if (!us.hasData || !ws.hasData) return const Loading();
            final u = us.data!, w = ws.data!;
            final photo = '${u['photoUrl'] ?? ''}';
            return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              GradientCard(child: Column(children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.white24, backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null),
                const SizedBox(height: 12),
                Text('${u['displayName'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text('${u['email'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(u['vip'] == true ? '👑 VIP member' : 'Free member', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(children: [
                    const Text('Coins', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.toll, size: 18, color: Color(0xFFFFD66B)), const SizedBox(width: 4),
                      Text(fmtCoins(w['balance']), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))]),
                  ])),
                  Expanded(child: Column(children: [
                    const Text('Worth', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(money(w['balance']), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ])),
                  Expanded(child: Column(children: [
                    const Text('Lifetime', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(fmtCoins(w['totalEarned']), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ])),
                ]),
              ])),
              const SectionTitle('Account'),
              Card(child: Column(children: [
                _row(c, Icons.fingerprint, 'User ID', uid, copy: true),
                _row(c, Icons.card_giftcard, 'Referral code', '${u['referralCode'] ?? ''}', copy: true),
                _row(c, Icons.calendar_month, 'Member since', fmtDt(u['created'], 10)),
              ])),
              const SectionTitle('Support'),
              if (!hasSupport) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Support details are not available yet.'))),
              if (email.isNotEmpty)
                _tile(Icons.email_outlined, Colors.redAccent, 'Email support', email, () => openUrl(c,
                    'mailto:$email?subject=${Uri.encodeComponent('Support request')}&body=${Uri.encodeComponent('User ID: $uid\n\n')}')),
              if (wa.isNotEmpty)
                _tile(Icons.chat, const Color(0xFF25D366), 'WhatsApp support', _s('supportWhatsapp'), () => openUrl(c,
                    'https://wa.me/$wa?text=${Uri.encodeComponent('${_s('supportMessage')}\nUser ID: $uid')}')),
              if (link.isNotEmpty) _tile(Icons.support_agent, kBrand, 'Help center', link, () => openUrl(c, link)),
              if (hours.isNotEmpty && hasSupport) Padding(padding: const EdgeInsets.fromLTRB(6, 4, 6, 0), child: Text('Support hours: $hours', style: Theme.of(c).textTheme.bodySmall)),
              const SectionTitle('More'),
              _tile(Icons.info_outline, Colors.blue, _s('appInfoTitle').isEmpty ? 'App info' : _s('appInfoTitle'), 'About, version, privacy & terms',
                  () => Navigator.push(c, MaterialPageRoute(builder: (_) => AppInfoPage(config: config)))),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                icon: const Icon(Icons.logout), label: const Text('Sign out'),
                onPressed: () async {
                  final ok = await showDialog<bool>(context: c, builder: (_) => AlertDialog(content: const Text('Sign out of your account?'), actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign out'))]));
                  if (ok == true) logout();
                }),
            ]);
          },
        ),
      ),
    );
  }
}

class AppInfoPage extends StatelessWidget {
  final Map<String, dynamic> config;
  const AppInfoPage({super.key, required this.config});
  @override
  Widget build(BuildContext c) {
    String s(String k) => '${config[k] ?? ''}'.trim();
    final privacy = s('privacyUrl'), terms = s('termsUrl');
    return Scaffold(
      appBar: AppBar(title: Text(s('appInfoTitle').isEmpty ? 'App info' : s('appInfoTitle'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        GradientCard(child: Column(children: [
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet_rounded, size: 44, color: Colors.white)),
          const SizedBox(height: 10),
          Text(s('appName').isEmpty ? 'Earning App' : s('appName'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          FutureBuilder<PackageInfo>(future: PackageInfo.fromPlatform(), builder: (c, p) =>
              Text(p.hasData ? 'Version ${p.data!.version}' : '', style: const TextStyle(color: Colors.white70))),
        ])),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(s('appInfoText').isEmpty ? 'No information added yet.' : s('appInfoText'), style: const TextStyle(height: 1.5)))),
        if (privacy.isNotEmpty) Card(child: ListTile(leading: const Icon(Icons.privacy_tip_outlined, color: kBrand), title: const Text('Privacy policy'), trailing: const Icon(Icons.open_in_new, size: 18), onTap: () => openUrl(c, privacy))),
        if (terms.isNotEmpty) Card(child: ListTile(leading: const Icon(Icons.description_outlined, color: kBrand), title: const Text('Terms & conditions'), trailing: const Icon(Icons.open_in_new, size: 18), onTap: () => openUrl(c, terms))),
      ]),
    );
  }
}
