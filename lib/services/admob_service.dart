import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _habitsCompletedCount = 0;

  // Ad IDs - Test vs Production
  static const bool _useTestAds = true; // Set to false for production

  // Test Ad IDs (always work for testing)
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // Production Ad IDs
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-6635484259161782/3348678799';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-6635484259161782/3348678799';

  String get interstitialAdUnitId {
    if (_useTestAds) {
      debugPrint('🧪 Using TEST ad unit ID');
      return _testInterstitialAdUnitId;
    }

    if (Platform.isAndroid) {
      debugPrint('📱 Using PRODUCTION Android ad unit ID');
      return _androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      debugPrint('🍎 Using PRODUCTION iOS ad unit ID');
      return _iosInterstitialAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  Future<void> initialize() async {
    try {
      debugPrint('🔧 Initializing AdMob with App ID: ca-app-pub-6635484259161782~4871543834');
      await MobileAds.instance.initialize();
      debugPrint('✅ AdMob initialized successfully');
      await _loadHabitsCompletedCount();
      debugPrint('📊 Habits completed count loaded: $_habitsCompletedCount');
      _loadInterstitialAd();
    } catch (e) {
      // Handle initialization errors gracefully (e.g., in test environment)
      debugPrint('❌ AdMob initialization failed: $e');
    }
  }

  void _loadInterstitialAd() {
    debugPrint('📱 Loading interstitial ad with Unit ID: $interstitialAdUnitId');
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('✅ Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _setFullScreenContentCallback();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Failed to load interstitial ad: ${error.message}');
          debugPrint('   Error code: ${error.code}');
          debugPrint('   Error domain: ${error.domain}');
          _isAdLoaded = false;
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 30), () {
            debugPrint('🔄 Retrying ad load...');
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  void _setFullScreenContentCallback() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        debugPrint('📺 Interstitial ad displayed');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('👋 Interstitial ad dismissed');
        ad.dispose();
        _isAdLoaded = false;
        // Load a new ad for next time
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('❌ Failed to show interstitial ad: ${error.message}');
        ad.dispose();
        _isAdLoaded = false;
        // Load a new ad for next time
        _loadInterstitialAd();
      },
    );
  }

  Future<void> showInterstitialAd({
    VoidCallback? onAdClosed,
    bool force = false,
  }) async {
    debugPrint('🎯 Attempting to show interstitial ad - Loaded: $_isAdLoaded');

    if (!_isAdLoaded || _interstitialAd == null) {
      debugPrint('⚠️ No ad available to show');
      onAdClosed?.call();
      return;
    }

    try {
      debugPrint('🚀 Showing interstitial ad...');
      await _interstitialAd!.show();
      onAdClosed?.call();
    } catch (e) {
      debugPrint('❌ Error showing ad: $e');
      onAdClosed?.call();
    }
  }

  // Show ad after habit creation
  Future<void> showAdAfterHabitCreation({VoidCallback? onAdClosed}) async {
    await showInterstitialAd(onAdClosed: onAdClosed);
  }

  // Show ad after Pomodoro session
  Future<void> showAdAfterPomodoroSession({VoidCallback? onAdClosed}) async {
    await showInterstitialAd(onAdClosed: onAdClosed);
  }

  // Show ad after every 3 habits completion
  Future<void> incrementHabitCompletion({VoidCallback? onAdClosed}) async {
    _habitsCompletedCount++;
    await _saveHabitsCompletedCount();

    debugPrint('📈 Habit completion count: $_habitsCompletedCount');

    if (_habitsCompletedCount % 3 == 0) {
      debugPrint('🎯 Showing ad after 3 habits completed!');
      await showInterstitialAd(onAdClosed: onAdClosed);
    } else {
      debugPrint('⏳ ${3 - (_habitsCompletedCount % 3)} more habits until next ad');
      onAdClosed?.call();
    }
  }

  // Show ad in habit details screen
  Future<void> showAdInHabitDetails({VoidCallback? onAdClosed}) async {
    await showInterstitialAd(onAdClosed: onAdClosed);
  }

  // Save habits completed count to SharedPreferences
  Future<void> _saveHabitsCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('habits_completed_count', _habitsCompletedCount);
  }

  // Load habits completed count from SharedPreferences
  Future<void> _loadHabitsCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    _habitsCompletedCount = prefs.getInt('habits_completed_count') ?? 0;
  }

  // Reset habits completed count (useful for testing)
  Future<void> resetHabitsCompletedCount() async {
    _habitsCompletedCount = 0;
    await _saveHabitsCompletedCount();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}