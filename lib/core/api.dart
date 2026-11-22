import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ====== CHANGE THESE TWO VALUES ======
const kPbUrl = 'http://127.0.0.1:8090'; // server on this phone (Termux). Change to https://... when hosted
const kGoogleWebClientId = '68828443779-5krob9mdf3006434eg4a2omlbhmqhqu8.apps.googleusercontent.com';
// =====================================

late PocketBase pb;

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}

/// Logged-in user's record id (read from the PocketBase auth token).
String get uid {
  try {
    final p = pb.authStore.token.split('.')[1];
    final j = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(p))));
    return j['id'] as String;
  } catch (_) {
    return '';
  }
}

Future<void> initApi() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('pb_auth');
  pb = PocketBase(
    kPbUrl,
    authStore: AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: (saved == null || saved.isEmpty) ? null : saved,
    ),
  );
  if (pb.authStore.isValid) {
    try {
      await pb.collection('app_users').authRefresh().timeout(const Duration(seconds: 8));
    } on ClientException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) pb.authStore.clear();
    } catch (_) {}
  }
}

Future<void> loginWithGoogle(String referral) async {
  GoogleSignInAccount? g;
  late GoogleSignInAuthentication a;
  try {
    g = await GoogleSignIn(serverClientId: kGoogleWebClientId).signIn();
    if (g == null) return;
    a = await g.authentication;
  } on PlatformException catch (e) {
    final m = '${e.message}';
    if (m.contains('10')) {
      throw ApiError('Google error 10: this app (package name + signing SHA-1) is not registered as an Android client in the same Google Cloud project as the Web client id.');
    }
    if (m.contains('12500')) throw ApiError('Google sign-in error 12500: check OAuth consent screen / support email in Google Cloud.');
    if (m.contains('7') && e.code == 'network_error') throw ApiError('No internet connection.');
    throw ApiError('Google sign-in failed (${e.code}). Check Google Cloud setup.');
  }
  if (a.idToken == null) throw ApiError('Google token missing. Check your Google client id setup.');
  try {
    final r = await pb.send('/api/earn/google-login', method: 'POST', body: {'idToken': a.idToken, 'referralCode': referral, 'app': 'user'});
    pb.authStore.save(r['token'] as String, RecordModel.fromJson(Map<String, dynamic>.from(r['record'] as Map)));
  } on ClientException catch (e) {
    throw ApiError(_msg(e));
  }
}

Future<void> logout() async {
  try {
    await GoogleSignIn().signOut();
  } catch (_) {}
  pb.authStore.clear();
}

String _msg(ClientException e) {
  final m = e.response['message'];
  return (e.statusCode == 0 || m == null || '$m'.isEmpty) ? 'Network error. Try again.' : '$m';
}

const _routes = {
  'claimScratch': '/api/earn/scratch',
  'claimSpin': '/api/earn/spin',
  'submitVipPayment': '/api/earn/vip-payment',
  'requestWithdrawal': '/api/earn/withdraw',
};

/// Calls a server route (replaces Firebase Cloud Functions).
Future<Map<String, dynamic>> call(String name, [Map<String, dynamic>? data]) async {
  try {
    final r = await pb.send(_routes[name]!, method: 'POST', body: data ?? {});
    return Map<String, dynamic>.from(r as Map);
  } on ClientException catch (e) {
    if (e.statusCode == 401) pb.authStore.clear();
    throw ApiError(_msg(e));
  } catch (_) {
    throw ApiError('Network error. Try again.');
  }
}

Map<String, dynamic> rec(RecordModel r) => {...r.data, 'id': r.id};

/// Live list: loads once, then reloads on every realtime event of the collection.
Stream<List<Map<String, dynamic>>> listStream(String col, {String? filter, String? sort, int limit = 50}) =>
    _live<List<Map<String, dynamic>>>(col, '*', () async {
      final r = await pb.collection(col).getList(page: 1, perPage: limit, filter: filter, sort: sort);
      return r.items.map(rec).toList();
    });

/// Live single record by id ({} when missing).
Stream<Map<String, dynamic>> oneStream(String col, String id) =>
    _live<Map<String, dynamic>>(col, id, () async {
      try {
        return rec(await pb.collection(col).getOne(id));
      } on ClientException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) return <String, dynamic>{};
        rethrow;
      }
    });

/// Live first record matching a filter ({} when none).
Stream<Map<String, dynamic>> firstStream(String col, String filter) =>
    _live<Map<String, dynamic>>(col, '*', () async {
      final r = await pb.collection(col).getList(page: 1, perPage: 1, filter: filter);
      return r.items.isEmpty ? <String, dynamic>{} : rec(r.items.first);
    });

Stream<T> _live<T>(String col, String topic, Future<T> Function() load) {
  late final StreamController<T> c;
  UnsubscribeFunc? unsub;
  var dead = false;
  Future<void> run() async {
    try {
      final v = await load();
      if (!c.isClosed) c.add(v);
    } catch (e) {
      if (!c.isClosed) c.addError(e);
    }
  }

  c = StreamController<T>(
    onListen: () async {
      await run();
      try {
        final u = await pb.collection(col).subscribe(topic, (_) => run());
        if (dead) {
          await u();
        } else {
          unsub = u;
        }
      } catch (e) {
        debugPrint('realtime subscribe failed: $e');
      }
    },
    onCancel: () async {
      dead = true;
      await unsub?.call();
    },
  );
  return c.stream;
}

const settingsId = 'appsettings0001';

/// Reads the public settings record with a plain request (no model parsing, so nothing can break here
/// except the network itself).
Future<Map<String, dynamic>> loadSettings() async {
  final r = await pb.send('/api/collections/app_settings/records/$settingsId');
  final raw = '${(r as Map)['data'] ?? '{}'}';
  final d = jsonDecode(raw);
  return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
}

String _hint(String e) {
  final t = e.toLowerCase();
  if (t.contains('cleartext')) return 'FIX: add android:usesCleartextTraffic="true" to <application> in AndroidManifest.xml (needed for http:// addresses), then rebuild.';
  if (t.contains('refused')) return 'FIX: nothing is listening at this address. Start the server (bash ~/pb/start.sh) and check the port 8090.';
  if (t.contains('timed out') || t.contains('timeout')) return 'FIX: address is wrong, the tunnel is down, or the phone is on another network.';
  if (t.contains('host lookup') || t.contains('socketexception')) return 'FIX: wrong domain/IP in kPbUrl, or no internet.';
  if (t.contains('handshake') || t.contains('certificate')) return 'FIX: https certificate problem. Use the exact https address of the tunnel.';
  return '';
}

/// Connection test shown on the "Cannot connect" screen.
Future<String> diagnose() async {
  final b = StringBuffer('Server address (kPbUrl):\n$kPbUrl\n\n');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(Uri.parse('$kPbUrl/api/health'));
    final res = await req.close().timeout(const Duration(seconds: 8));
    final body = await res.transform(utf8.decoder).join();
    b.writeln('1) Health check: HTTP ${res.statusCode}');
    b.writeln(body.length > 100 ? body.substring(0, 100) : body);
  } catch (e) {
    b.writeln('1) Health check FAILED:\n$e');
    final h = _hint('$e');
    if (h.isNotEmpty) b.writeln('\n$h');
  } finally {
    client.close(force: true);
  }
  try {
    final st = await loadSettings();
    b.writeln('\n2) App settings: OK (${st.length} values)');
  } catch (e) {
    b.writeln('\n2) App settings FAILED:\n$e');
    final h = _hint('$e');
    if (h.isNotEmpty) b.writeln('\n$h');
  }
  return b.toString();
}

/// Firestore-style paths kept so the UI code stays the same:
///  users/{uid}  wallets/{uid}  app_settings/main  users/{uid}/daily/{yyyy-mm-dd}
Stream<Map<String, dynamic>> docStream(String path) {
  final p = path.split('/');
  if (p[0] == 'app_settings') return _live<Map<String, dynamic>>('app_settings', settingsId, loadSettings);
  if (p[0] == 'wallets') return firstStream('wallets', 'user = "${p[1]}"');
  if (p[0] == 'users' && p.length == 2) return oneStream('app_users', p[1]);
  if (p[0] == 'users' && p.length == 4) return firstStream('daily', 'user = "${p[1]}" && date = "${p[3]}"');
  throw ArgumentError('Unknown path $path');
}

String today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

/// PocketBase date string ("2026-11-03 10:00:00.000Z") -> local DateTime.
DateTime? dt(dynamic v) {
  if (v == null || '$v'.isEmpty) return null;
  return DateTime.tryParse('$v'.replaceFirst(' ', 'T'))?.toLocal();
}

String fmtDt(dynamic v, [int len = 16]) {
  final d = dt(v);
  if (d == null) return '';
  final s = d.toString();
  return s.length > len ? s.substring(0, len) : s;
}
