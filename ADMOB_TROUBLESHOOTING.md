# AdMob Integration Troubleshooting Guide

## 🚀 Quick Test Setup

I've configured your app to use **TEST ADS** first to verify the integration works. Here's what you need to know:

### Current Configuration
- ✅ Android manifest updated with test App ID
- ✅ AdMob service configured for test ads (`_useTestAds = true`)
- ✅ Debug logging enabled
- ✅ Test debug screen created

## 🔧 Step-by-Step Testing

### 1. Run the App and Check Debug Output

Look for these debug messages in your console:
```
🔧 Initializing AdMob with App ID: ca-app-pub-6635484259161782~4871543834
✅ AdMob initialized successfully
📊 Habits completed count loaded: 0
🧪 Using TEST ad unit ID
📱 Loading interstitial ad with Unit ID: ca-app-pub-3940256099942544/1033173712
✅ Interstitial ad loaded successfully
```

### 2. Test Ad Locations

**Test each ad location:**
1. **Habit Creation**: Create a new habit → should show test ad
2. **Pomodoro Session**: Start and stop a Pomodoro → should show test ad
3. **Habit Completion**: Mark 3 habits as complete → should show test ad on 3rd completion
4. **Habit Details**: Open any habit details screen → should show test ad after 1 second

### 3. Use the Debug Screen (Optional)

Add this route to your app to access the debug screen:
```dart
// In your main.dart routes
'/debug-ads': (context) => const AdsDebugScreen(),
```

## 🐛 Common Issues & Solutions

### Issue 1: "No ad available to show"
**Symptoms**: Debug log shows `⚠️ No ad available to show`
**Causes**:
- Network connectivity issues
- Ad not loaded yet
- AdMob account issues

**Solutions**:
1. Ensure internet connection
2. Wait 30 seconds after app launch for ad to load
3. Check if you see `✅ Interstitial ad loaded successfully` in logs

### Issue 2: Ad fails to load
**Symptoms**: Debug log shows `❌ Failed to load interstitial ad`
**Solutions**:
1. Check internet connection
2. Verify App ID in AndroidManifest.xml
3. Try restarting the app

### Issue 3: Test ads don't show
**Symptoms**: No ads appear even with test configuration
**Solutions**:
1. Ensure `_useTestAds = true` in AdMobService
2. Clean and rebuild: `flutter clean && flutter pub get`
3. Restart the app completely

## 🔄 Switching to Production Ads

Once test ads work, switch to production:

### 1. Update AdMob Service
```dart
static const bool _useTestAds = false; // Change to false
```

### 2. Update Android Manifest
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-6635484259161782~4871543834"/>
```

### 3. Important Production Notes
- **New AdMob accounts**: May take 24-48 hours for ads to show
- **Limited inventory**: Production ads may not always be available
- **Geographic restrictions**: Ads availability varies by location
- **App review**: Google may need to review your app before serving ads

## 📊 Debug Commands

### View current habit completion count:
The debug logs will show: `📊 Habits completed count loaded: X`

### Reset habit completion counter:
Call `AdMobService().resetHabitsCompletedCount()`

### Force show ad:
Each ad method has debug logging that shows if it's attempting to display

## 🆘 Still Not Working?

### 1. Check AdMob Console
- Verify your App ID and Ad Unit IDs are correct
- Check if your account is approved
- Look for any policy violations

### 2. Test Device Requirements
- Use a physical device (not emulator) for production ads
- Ensure device has Google Play Services
- Test with different devices if possible

### 3. Network & Permissions
- Verify INTERNET permission in AndroidManifest.xml
- Test with different network connections (WiFi vs mobile data)
- Check if your firewall/VPN is blocking ad requests

## 📱 Final Production Checklist

- [ ] `_useTestAds = false` in AdMobService
- [ ] Production App ID in AndroidManifest.xml
- [ ] App published/in review on Play Store
- [ ] AdMob account approved and linked
- [ ] Tested on physical device
- [ ] Debug logging can be disabled for release

## 🚨 Emergency Fallback

If ads still don't work, you can temporarily disable them:
```dart
// In each ad call location, wrap with:
if (false) { // Set to true when ads are working
  AdMobService().showAdAfterHabitCreation();
}
```

Remember: **Test ads should work immediately**, but **production ads may take time to appear** for new apps/accounts.