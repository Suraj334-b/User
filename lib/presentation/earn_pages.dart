import 'dart:math';
import 'package:flutter/material.dart';
import '../core/ads_service.dart';
import '../core/api.dart';
import '../core/ui.dart';

const _testRewarded = 'ca-app-pub-3940256099942544/5224354917'; // Google test unit

class EarnPage extends StatelessWidget {
  final Map<String, dynamic> config;
  const EarnPage({super.key, required this.config});
  @override
  Widget build(BuildContext c) {
    Widget tile(String key, IconData i, String t, String sub, List<Color> colors, Widget page) => config[key] == false
        ? const SizedBox()
        : Padding(padding: const EdgeInsets.only(bottom: 14), child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
            child: GradientCard(colors: colors, padding: const EdgeInsets.all(20), child: Row(children: [
              Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Icon(i, size: 32, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Colors.white70)),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            ]))));
    return Scaffold(appBar: AppBar(title: const Text('Earn')), body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 14), child: Text('Pick a way to earn today', style: Theme.of(c).textTheme.bodyMedium)),
      tile('scratchEnabled', Icons.card_giftcard, 'Scratch Card', 'Scratch to reveal your reward', const [Color(0xFFFF7A45), Color(0xFFFF4D8D)], const ScratchPage()),
      tile('spinEnabled', Icons.casino, 'Spin Wheel', 'Spin and win instantly', const [Color(0xFF2EC4B6), Color(0xFF4D8DFF)], SpinPage(config: config)),
      tile('adsEnabled', Icons.play_circle_fill, 'Watch Ads', 'Watch a short video and earn', const [kBrand, kBrand2], AdsPage(config: config, vip: false)),
    ]));
  }
}

class ScratchPage extends StatefulWidget {
  const ScratchPage({super.key});
  @override
  State<ScratchPage> createState() => _Sc();
}

class _Sc extends State<ScratchPage> {
  int moves = 0; bool busy = false; double? amount;
  Future<void> claim() async {
    setState(() => busy = true);
    try {
      final r = await call('claimScratch');
      if (mounted) setState(() => amount = (r['amount'] as num).toDouble());
    } catch (e) {
      if (mounted) { toast(context, e.toString()); setState(() => moves = 0); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext c) {
    final done = amount != null;
    return Scaffold(appBar: AppBar(title: const Text('Scratch Card')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(done ? 'You won!' : 'Rub the card with your finger', style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      GestureDetector(
        onPanUpdate: (_) {
          if (amount == null && !busy) { setState(() => moves++); if (moves > 35) claim(); }
        },
        child: Container(width: 310, height: 190,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: const Color(0xFFFFB020).withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 10))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(fit: StackFit.expand, children: [
            Container(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFD66B), Color(0xFFFFA62B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(done ? Icons.emoji_events : Icons.help_outline, size: 40, color: Colors.black54),
                Text(done ? coins(amount) : '?', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.black87)),
              ])),
            AnimatedOpacity(duration: const Duration(milliseconds: 250), opacity: done ? 0.0 : (1 - moves / 36).clamp(0.12, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade400, Colors.blueGrey.shade200, Colors.grey.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                alignment: Alignment.center,
                child: Text(busy ? 'Please wait...' : 'SCRATCH HERE', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white)))),
          ])))),
      const SizedBox(height: 20),
      if (!done) SizedBox(width: 240, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(minHeight: 8, value: (moves / 36).clamp(0.0, 1.0).toDouble()))),
      if (done) FilledButton.icon(icon: const Icon(Icons.refresh), onPressed: () => setState(() { amount = null; moves = 0; }), label: const Text('Next card')),
    ]))));
  }
}

class SpinPage extends StatefulWidget {
  final Map<String, dynamic> config;
  const SpinPage({super.key, required this.config});
  @override
  State<SpinPage> createState() => _Sp();
}

class _Sp extends State<SpinPage> with SingleTickerProviderStateMixin {
  late final AnimationController ctl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  double target = 0; bool busy = false;
  List get segs => widget.config['spinSegments'] ?? [{'amount': 0}, {'amount': 0.5}, {'amount': 1}, {'amount': 2}];
  Future<void> spin() async {
    setState(() => busy = true);
    try {
      final r = await call('claimSpin');
      final n = segs.length, idx = r['segment'] as int, seg = 2 * pi / n;
      target = 2 * pi * 5 + (2 * pi - (idx * seg + seg / 2)); // pointer is at top
      await ctl.forward(from: 0);
      if (mounted) toast(context, 'You won ${coins(r['amount'])}');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  void dispose() { ctl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Spin Wheel')), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.arrow_drop_down_rounded, size: 56, color: kBrand),
    Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: kBrand.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))]),
      child: AnimatedBuilder(animation: ctl, builder: (_, __) => Transform.rotate(
        angle: Curves.easeOutCubic.transform(ctl.value) * target,
        child: CustomPaint(size: const Size(300, 300), painter: _Wheel(segs.map<String>((e) => fmtCoins(e['amount'] as num)).toList()))))),
    const SizedBox(height: 28),
    SizedBox(width: 220, child: FilledButton.icon(icon: const Icon(Icons.casino), onPressed: busy ? null : spin, label: Text(busy ? 'SPINNING...' : 'SPIN NOW'))),
  ])));
}

class _Wheel extends CustomPainter {
  final List<String> labels;
  _Wheel(this.labels);
  static const _pal = [Color(0xFF6C4DFF), Color(0xFFFF5DA2), Color(0xFFFFB020), Color(0xFF2EC4B6), Color(0xFF4D8DFF), Color(0xFFFF7A45)];
  @override
  void paint(Canvas cv, Size s) {
    final r = s.width / 2, n = labels.length, a = 2 * pi / n;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r - 6);
    for (var i = 0; i < n; i++) {
      cv.drawArc(rect, i * a - pi / 2, a, true, Paint()..color = _pal[i % _pal.length]);
      final tp = TextPainter(text: TextSpan(text: labels[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, shadows: [Shadow(color: Colors.black38, blurRadius: 3)])), textDirection: TextDirection.ltr)..layout();
      final ang = i * a - pi / 2 + a / 2;
      cv.save();
      cv.translate(r + cos(ang) * r * .62, r + sin(ang) * r * .62);
      cv.rotate(ang + pi / 2);
      tp.paint(cv, Offset(-tp.width / 2, -tp.height / 2));
      cv.restore();
    }
    cv.drawCircle(Offset(r, r), r - 6, Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = Colors.white);
    cv.drawCircle(Offset(r, r), 26, Paint()..color = Colors.white);
    cv.drawCircle(Offset(r, r), 14, Paint()..color = kBrand);
  }
  @override
  bool shouldRepaint(_) => false;
}

/// Rewarded ad screen. Coins are credited ONLY by the server (AdMob server-side verification).
class AdsPage extends StatefulWidget {
  final Map<String, dynamic> config;
  final bool vip;
  const AdsPage({super.key, required this.config, required this.vip});
  @override
  State<AdsPage> createState() => _AdsState();
}

class _AdsState extends State<AdsPage> {
  bool loading = false, running = false;
  int countdown = 0;
  String status = '';

  String get mode => widget.vip ? 'vip' : 'ad';
  String get unit {
    final v = '${widget.config[widget.vip ? 'vipAdUnitId' : 'adUnitId'] ?? ''}'.trim();
    return isValidUnitId(v) ? v : kTestRewardedUnit;
  }

  bool get usingTest => unit == kTestRewardedUnit;

  /// Loads one ad and shows it. Returns true when the user watched it to the end.
  Future<bool> _loadAndShow() async {
    setState(() {
      loading = true;
      status = 'Loading ad...';
    });
    await AdsService.instance.init();
    final r = await AdsService.instance.load(unit);
    if (!mounted) {
      r.ad?.dispose();
      return false;
    }
    final ad = r.ad;
    if (ad == null) {
      setState(() {
        loading = false;
        running = false;
        status = r.error ?? 'No ad available.';
      });
      return false;
    }
    setState(() {
      loading = false;
      status = 'Showing ad...';
    });
    final s = await AdsService.instance.show(ad, userId: uid, mode: mode);
    if (!mounted) return false;
    if (s.error != null) {
      setState(() {
        running = false;
        status = 'Could not show the ad: ${s.error}';
      });
      return false;
    }
    setState(() => status = s.earned ? 'Ad completed. Verifying... your coins appear in a few seconds.' : 'The ad was closed early. No coins added.');
    return s.earned;
  }

  Future<void> _watchOnce() async {
    if (loading) return;
    await _loadAndShow();
  }

  /// VIP: ads keep coming automatically with a visible 5 second pause. STOP ends it at any time.
  Future<void> _vipLoop() async {
    setState(() => running = true);
    while (running && mounted) {
      final ok = await _loadAndShow();
      if (!ok || !running || !mounted) break;
      for (countdown = 5; countdown > 0 && running && mounted; countdown--) {
        setState(() {});
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    if (mounted) {
      setState(() {
        running = false;
        countdown = 0;
      });
    }
  }

  @override
  void dispose() {
    running = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: Text(widget.vip ? 'VIP Earning' : 'Watch Ads')),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
          GradientCard(
            colors: widget.vip ? const [Color(0xFFFFB020), Color(0xFFFF7A45)] : const [kBrand, kBrand2],
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Icon(widget.vip ? Icons.workspace_premium : Icons.play_circle_fill, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(widget.vip ? 'Auto-earn with VIP' : 'Watch & Earn', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Coins are added after the ad is verified', style: TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 12),
          StreamBuilder<Map<String, dynamic>>(
            stream: docStream('users/$uid/daily/${today()}'),
            builder: (c, s) {
              final n = s.data?[widget.vip ? 'vipAds' : 'ads'] ?? 0;
              return Row(children: [
                StatCard('Completed today', '$n', Icons.check_circle),
                StreamBuilder<Map<String, dynamic>>(
                  stream: docStream('wallets/$uid'),
                  builder: (c, w) => StatCard(widget.vip ? 'VIP earnings' : 'Total earned', coins(w.data?[widget.vip ? 'vipEarned' : 'totalEarned']), Icons.toll),
                ),
              ]);
            },
          ),
          const SizedBox(height: 16),
          if (usingTest)
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.orange),
                title: const Text('Test ads are being used'),
                subtitle: const Text('Set a valid ad unit id in the admin panel (App Settings). Test ads do not give coins.'),
              ),
            ),
          if (countdown > 0) Center(child: Text('Next ad in $countdown s', style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
          if (loading) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
          if (status.isNotEmpty && !loading) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(status, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          if (widget.vip)
            Row(children: [
              Expanded(child: FilledButton.icon(icon: const Icon(Icons.play_arrow), onPressed: running ? null : _vipLoop, label: const Text('START'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.tonalIcon(icon: const Icon(Icons.stop), onPressed: running ? () => setState(() => running = false) : null, label: const Text('STOP'))),
            ])
          else
            FilledButton.icon(icon: const Icon(Icons.play_arrow), onPressed: loading ? null : _watchOnce, label: const Text('Watch ad')),
          const SizedBox(height: 10),
          Text('Coins are added only after the ad is fully watched and verified.', textAlign: TextAlign.center, style: Theme.of(c).textTheme.bodySmall),
        ]),
      );
}
