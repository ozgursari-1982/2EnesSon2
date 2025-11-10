# 🚀 Deployment Kılavuzu

## 📱 Web Uygulamasını Median.co'ya Yükleme

### 1. Build Edilmiş Dosyalar
Production build dosyaları `build/web` klasöründe hazır.

### 2. Median.co'ya Yükleme Adımları

#### Seçenek A: FTP/SFTP ile Yükleme
1. Median.co hesabınıza giriş yapın
2. FTP/SFTP bilgilerinizi alın
3. `build/web` klasöründeki **TÜM** dosyaları sunucuya yükleyin
4. Dosyalar `public_html` veya `www` klasörüne gitmeli

#### Seçenek B: Git ile Yükleme
1. Median.co Git repository'nizi hazırlayın
2. `build/web` klasöründeki dosyaları commit edin
3. Push yapın

#### Seçenek C: Median.co Dashboard
1. Median.co dashboard'a giriş yapın
2. "Deploy" veya "Upload" bölümüne gidin
3. `build/web` klasörünü zip'leyip yükleyin

### 3. Önemli Yapılandırmalar

#### Firebase Web App ID Ekleme
1. [Firebase Console](https://console.firebase.google.com/) → Projeniz
2. Project Settings → Your apps → Web app ekleyin
3. `appId`'yi kopyalayın (format: `1:541014953985:web:xxxxx`)
4. `lib/firebase_options.dart` dosyasında güncelleyin:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'AIzaSyBKaWdMwSUWyHo9KsXb1KAjTNZjiBTryUI',
     appId: '1:541014953985:web:YOUR_ACTUAL_WEB_APP_ID', // ← Buraya gerçek ID
     // ...
   );
   ```
5. Tekrar build edin: `flutter build web --release`

#### Firebase Hosting Kuralları (Opsiyonel)
Eğer Firebase Hosting kullanıyorsanız, `firebase.json` dosyasına ekleyin:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### 4. CORS Ayarları
Firebase Storage ve Firestore için CORS ayarlarını yapın:
- Firebase Console → Storage → Rules
- Firebase Console → Firestore → Rules

### 5. Domain Yapılandırması
Median.co'da domain'inizi yapılandırın ve SSL sertifikası aktif edin.

---

## 📱 iOS için Derleme

### Gereksinimler
- macOS (iOS build için zorunlu)
- Xcode (App Store'dan indirin)
- CocoaPods: `sudo gem install cocoapods`
- Apple Developer hesabı (ücretsiz veya ücretli)

### 1. iOS Yapılandırması

#### Firebase iOS Yapılandırması
1. Firebase Console → Project Settings → iOS app ekleyin
2. Bundle ID: `com.example.ai_teacher_app` (veya kendi ID'niz)
3. `GoogleService-Info.plist` dosyasını indirin
4. Dosyayı `ios/Runner/` klasörüne kopyalayın

#### iOS Podfile Güncelleme
```bash
cd ios
pod install
cd ..
```

### 2. iOS Build Komutları

#### Debug Build (Test için)
```bash
flutter build ios --debug
```

#### Release Build (App Store için)
```bash
flutter build ios --release
```

#### IPA Dosyası Oluşturma
```bash
flutter build ipa
```

### 3. Xcode ile Açma ve Yayınlama
```bash
open ios/Runner.xcworkspace
```

Xcode'da:
1. Signing & Capabilities → Team seçin
2. Product → Archive
3. Distribute App → App Store Connect veya Ad Hoc

### 4. App Store Connect'e Yükleme
1. [App Store Connect](https://appstoreconnect.apple.com/) → My Apps
2. Yeni app oluşturun
3. Archive'ı yükleyin
4. App Store bilgilerini doldurun
5. Submit for Review

---

## 🔧 Sorun Giderme

### Web Build Sorunları

#### Build hatası alıyorsanız:
```bash
flutter clean
flutter pub get
flutter build web --release
```

#### Firebase hatası alıyorsanız:
- Firebase web app ID'sinin doğru olduğundan emin olun
- Firebase Console'da Authentication, Firestore, Storage aktif olduğundan emin olun

### iOS Build Sorunları

#### CocoaPods hatası:
```bash
cd ios
pod deintegrate
pod install
cd ..
```

#### Signing hatası:
- Xcode'da Signing & Capabilities bölümünden Team seçin
- Bundle Identifier'ı benzersiz yapın

---

## 📝 Notlar

- Web build dosyaları `build/web` klasöründe
- iOS build için macOS gerekli
- Her build'den önce `flutter clean` yapmanız önerilir
- Firebase yapılandırmalarını her platform için ayrı yapın

