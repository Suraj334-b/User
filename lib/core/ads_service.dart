import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's official TEST rewarded unit. Used only when no valid unit id is set in the admin panel.
const kTestRewardedUnit = 'ca-app-pub-3940256099942544/5224354917';

bool isValidUnitId(String s) => RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]{10}$').hasMatch(s);

class AdLoadResult {
  final RewardedAd? ad;
  final String? error;
  const AdLoadResult({this.ad, this.error});
}

class AdShowResult {
  final bool earned;
  final String? error;
  const AdShowResult({this.earned = false, this.error});
}

/// Thin, crash-proof wrapper around google_mobile_ads 9.x rewarded ads.
/// Coins are NEVER added here: the server adds them after Google's server-side verification (SSV).
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();
  bool _started = false;

  /// Safe to call many times, never throws, never blocks app start.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds.initialize failed: $e');
    }
  }

  String _loadError(LoadAdError e) {
    switch (e.code) {
      case 3:
        return 'No ad available right now. Try again in a minute.';
      case 2:
        return 'Network error while loading the ad.';
      case 1:
        return 'Invalid ad request. Check the ad unit id in the admin panel.';
      case 0:
        return 'Ad service error. Try again.';
      default:
        return '${e.message} (code ${e.code})';
    }
  }

  Future<AdLoadResult> load(String unitId) {
    final done = Completer<AdLoadResult>();
    final timer = Timer(const Duration(seconds: 30), () {
      if (!done.isCompleted) done.complete(const AdLoadResult(error: 'The ad request timed out.'));
    });
    try {
      RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (done.isCompleted) {
              ad.dispose(); // arrived after the timeout, nobody wants it
            } else {
              done.complete(AdLoadResult(ad: ad));
            }
          },
          onAdFailedToLoad: (err) {
            if (!done.isCompleted) done.complete(AdLoadResult(error: _loadError(err)));
          },
        ),
      );
    } catch (e) {
      if (!done.isCompleted) done.complete(AdLoadResult(error: '$e'));
    }
    return done.future.whenComplete(timer.cancel);
  }

  /// Completes when the ad is closed. `earned` only means Google reported the reward on the phone;
  /// the real credit comes from the server.
  Future<AdShowResult> show(RewardedAd ad, {required String userId, required String mode}) async {
    final done = Completer<AdShowResult>();
    var earned = false;
    try {
      await ad.setServerSideOptions(ServerSideVerificationOptions(userId: userId, customData: mode));
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          if (!done.isCompleted) done.complete(AdShowResult(earned: earned));
        },
        onAdFailedToShowFullScreenContent: (a, err) {
          a.dispose();
          if (!done.isCompleted) done.complete(AdShowResult(error: err.message));
        },
      );
      ad.show(onUserEarnedReward: (a, reward) => earned = true);
    } catch (e) {
      try {
        ad.dispose();
      } catch (_) {}
      if (!done.isCompleted) done.complete(AdShowResult(error: '$e'));
    }
    return done.future;
  }
}
