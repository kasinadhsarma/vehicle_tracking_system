# Google Maps API Setup Guide

## Step 1: Get Google Maps API Key

### From Google Cloud Console (NOT Firebase):

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Sign in with your Google account

2. **Create or Select Project**
   - Click "Select a project" dropdown
   - Either create new project or select existing one
   - Note: You can use the same project as your Firebase project

3. **Enable Google Maps JavaScript API**
   - Go to "APIs & Services" > "Library"
   - Search for "Maps JavaScript API"
   - Click on it and press "Enable"
   - Also enable "Places API" if you need location search

4. **Create API Key**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the generated API key

5. **Secure Your API Key (Recommended)**
   - Click on the API key to edit
   - Under "Application restrictions", select "HTTP referrers"
   - Add your domains (e.g., localhost:*, your-domain.com)
   - Under "API restrictions", select "Restrict key"
   - Choose "Maps JavaScript API" and "Places API"

## Step 2: Configure in Flutter Project

### For Web (Current Issue):
Replace the API key in `/web/index.html`:
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=geometry,places"></script>
```

### For Android:
Add to `/android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_ACTUAL_API_KEY"/>
```

### For iOS:
Add to `/ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
```

## Step 3: Update Configuration

Edit `/lib/core/config/maps_config.dart`:
```dart
static const String _developmentApiKey = 'YOUR_ACTUAL_API_KEY';
```

## Step 4: Test

1. Restart your Flutter app
2. Navigate to the Map page
3. You should see the actual Google Map instead of demo mode

## Troubleshooting

### Common Issues:
1. **"For development purposes only" watermark**: API key restrictions are too strict
2. **Gray map**: API key not configured or invalid
3. **"TypeError: Cannot read properties of undefined"**: API script not loaded

### Solutions:
1. Check API key is correctly copied
2. Ensure Maps JavaScript API is enabled
3. Verify API key restrictions allow your domain
4. Clear browser cache and restart app

## Cost Considerations

- Google Maps has a free tier with generous limits
- Monitor usage in Google Cloud Console
- Set up billing alerts to avoid unexpected charges
- Consider API key restrictions to prevent abuse

## Security Best Practices

1. **Never commit API keys to public repositories**
2. **Use environment variables for production**
3. **Restrict API keys by domain/IP**
4. **Monitor API usage regularly**
5. **Rotate keys periodically**
