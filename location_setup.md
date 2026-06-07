# Location Permission Setup

## Android
Add to android/app/src/main/AndroidManifest.xml BEFORE the <application> tag:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Windows
No extra setup needed — geolocator uses the Windows Location API automatically.
Windows may show a system prompt asking the user to allow location access.

## macOS
Add to macos/Runner/Info.plist inside the <dict> tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>QSOLog needs your location to set your station coordinates.</string>
```

Also add to macos/Runner/DebugProfile.entitlements and
macos/Runner/Release.entitlements inside the <dict> tag:

```xml
<key>com.apple.security.personal-information.location</key>
<true/>
```

## iOS
Add to ios/Runner/Info.plist inside the <dict> tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>QSOLog needs your location to set your station coordinates.</string>
```

## Linux
Install required package:
  sudo apt-get install -y libgeocode-glib-dev

No code changes needed — geolocator handles it automatically.
