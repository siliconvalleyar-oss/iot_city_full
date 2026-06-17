# 🚀 IoT City Flutter — Guía de Despliegue

> **Versión:** 1.0.0  
> **SDK:** Flutter 3.44+ / Dart 3.12+  
> **Target:** Android 16.0+, iOS, Web

---

## 📋 Requisitos

```bash
# Flutter SDK
flutter --version  # Flutter 3.44+

# Dart SDK
dart --version     # Dart 3.12+

# Dispositivo/Emulador Android
flutter devices    # Ver dispositivos disponibles
```

---

## 🛠️ Desarrollo

### Ejecutar en modo debug

```bash
# Android
flutter run

# Web
flutter run -d chrome

# Dispositivo específico
flutter run -d <device_id>
```

### Hot Reload

```bash
# Guardar archivo .dart → hot reload automático
# O presionar 'r' en la terminal
```

### Análisis estático

```bash
flutter analyze
```

### Tests

```bash
flutter test
```

---

## 📦 Build para Producción

### Android

```bash
# APK (compatible con cualquier Android)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# App Bundle (recomendado para Play Store)
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# APK split por ABI
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# → build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

### iOS

```bash
flutter build ios --release
# → build/ios/iphoneos/Runner.app

# Para TestFlight / App Store
# Abrir ios/Runner.xcworkspace en Xcode
# Product → Archive
```

### Web

```bash
flutter build web --release
# → build/web/
```

### Linux / macOS / Windows

```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

---

## 🔧 Configuración Android

### AndroidManifest.xml

```xml
<manifest>
    <!-- Permisos de internet -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="IoT City Dashboard"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
        </activity>
    </application>
</manifest>
```

### build.gradle (app)

```gradle
android {
    compileSdk 36  // Android 16.0
    defaultConfig {
        minSdk 36
        targetSdk 36
        versionCode 1
        versionName "1.0.0"
    }
}
```

---

## ⚙️ Configuración iOS

### Info.plist

```xml
<key>CFBundleDisplayName</key>
<string>IoT City Dashboard</string>
<key>CFBundleIdentifier</key>
<string>com.iotcity.dashboard</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>LSRequiresIPhoneOS</key>
<true/>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
</array>
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

---

## 🔗 Integración con Backend

```dart
// lib/config/constants.dart
class AppConstants {
  static const String baseUrl = 'http://192.168.1.100:5062/api';
  static const String wsUrl = 'ws://192.168.1.100:5062/api/dashboard/ws';
}
```

Para desarrollo, usar datos mock (ya configurado por defecto).

---

## 📱 CI/CD (Futuro)

### GitHub Actions

```yaml
name: Build Flutter App
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/*.apk
```

---

## 🐛 Solución de Problemas

### Error de compilación

```bash
flutter clean
flutter pub get
flutter run
```

### Error de Gradle

```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Error de dependencias

```bash
flutter pub cache repair
flutter pub get
```

### Error de versión Flutter

```bash
flutter channel stable
flutter upgrade
flutter doctor
```
