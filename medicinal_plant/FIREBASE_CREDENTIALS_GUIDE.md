# Firebase Credentials Update Guide

## ✅ Completed Steps

1. ✅ Updated `.gitignore` to exclude all platform directories
2. ✅ Created `keys_template.dart` with new web credentials
3. ✅ Committed changes to Git

## 📋 Next Steps to Complete

### Step 1: Update Your `lib/keys.dart` File

1. **Open** `keys_template.dart` (created in project root)
2. **Copy** all the content
3. **Paste** it into your existing `lib/keys.dart` file
4. **Replace** all placeholder values with actual credentials (see below)
5. **Delete** `keys_template.dart` after copying

**Note:** The web credentials are already filled in with your new Firebase config!

### Step 2: Get Missing Firebase Credentials

#### For Android:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **medicinal-plant-82aa9**
3. Click ⚙️ → **Project settings**
4. Scroll to **Your apps** → Select **Android app**
5. Download new **google-services.json**
6. Place it in: `android/app/google-services.json`
7. Open the file and find:
   - `current_key` → This is your `androidApiKey`
   - `mobilesdk_app_id` → This is your `androidAppId`

#### For iOS (if you have an iOS app):

1. Same Firebase Console → Select **iOS app**
2. Download new **GoogleService-Info.plist**
3. Place it in: `ios/Runner/GoogleService-Info.plist`
4. Open the file and find:
   - `API_KEY` → This is your `iosApiKey`
   - `GOOGLE_APP_ID` → This is your `iosAppId`
   - `CLIENT_ID` → This is your `iosClientId`
   - `REVERSED_CLIENT_ID` → This is your `iosReversedClientId`

### Step 3: Get Google Cloud API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **medicinal-plant-82aa9**
3. Navigate to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **API Key**
5. Copy the key → This is your `googleCloudApiKey`
6. **Restrict the key:**
   - Click **Edit API key**
   - Under **API restrictions**, select the APIs you use
   - Click **Save**

### Step 4: Get Google Gemini AI API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click **Create API Key**
3. Select your project: **medicinal-plant-82aa9**
4. Copy the key → This is your `geminiApiKey`

### Step 5: Get OneSignal Credentials (if using)

1. Go to [OneSignal Dashboard](https://app.onesignal.com/)
2. Select your app
3. Go to **Settings** → **Keys & IDs**
4. Copy:
   - **OneSignal App ID** → `oneSignalAppId`
   - **REST API Key** → `oneSignalRestApiKey`

### Step 6: Get OAuth Client IDs (for Google Sign-In)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Under **OAuth 2.0 Client IDs**, you'll see:
   - **Web client** → `googleSignInWebClientId`
   - **Android client** → `googleSignInAndroidClientId`
   - **iOS client** → `googleSignInIosClientId`

If they don't exist, create them:

- Click **+ CREATE CREDENTIALS** → **OAuth client ID**
- Select platform and fill in details

### Step 7: Get FCM Server Key (for backend notifications)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **medicinal-plant-82aa9**
3. Click ⚙️ → **Project settings** → **Cloud Messaging**
4. Under **Cloud Messaging API (Legacy)**, copy **Server key**
5. This is your `fcmServerKey`

**Note:** Legacy FCM is deprecated. Consider migrating to FCM HTTP v1 API.

## 🔒 Security Checklist

After updating all credentials:

- [ ] Verify `lib/keys.dart` is listed in `.gitignore`
- [ ] Run `git status` to ensure `keys.dart` is not tracked
- [ ] Enable **Firebase App Check** for additional security
- [ ] Set up **API key restrictions** in Google Cloud Console
- [ ] Monitor Firebase Console for unusual activity
- [ ] Delete `keys_template.dart` from your project
- [ ] Never share screenshots containing API keys

## 🚀 Testing

After updating all keys:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Test on each platform:
   - Android: `flutter run -d android`
   - Web: `flutter run -d chrome`
   - iOS: `flutter run -d ios` (if applicable)

## 📝 Quick Reference

Your Firebase Project Details:

- **Project ID:** medicinal-plant-82aa9
- **Project Name:** Medicinal Plant
- **Database Region:** asia-southeast1
- **Storage Bucket:** medicinal-plant-82aa9.appspot.com

## ⚠️ Important Notes

1. **Never commit** `lib/keys.dart` to Git
2. **Rotate keys** if they were exposed
3. **Use environment variables** for production deployments
4. **Keep backups** of your credentials in a secure password manager
5. **Review Firebase usage** regularly to detect unauthorized access

## 🆘 Troubleshooting

**If you see "API key not valid" errors:**

- Verify the key is correctly copied (no extra spaces)
- Check API restrictions in Google Cloud Console
- Ensure the API is enabled for your project

**If Google Sign-In fails:**

- Verify SHA-1 fingerprint is added to Firebase (Android)
- Check OAuth consent screen is configured
- Ensure client IDs match your app configuration

**If you need help:**

- Check Firebase Console for error logs
- Review Google Cloud Console audit logs
- Verify all required APIs are enabled

---

**Created:** 2025-12-23
**Last Updated:** 2025-12-23
