# 🚀 Firebase Hosting ile Yayınlama (En Kolay Yol)

## Adım 1: Firebase'e Giriş Yapın

Terminal'de şu komutu çalıştırın:
```bash
firebase login
```

Tarayıcı açılacak, Google hesabınızla giriş yapın.

## Adım 2: Firebase Projesini Bağlayın

```bash
firebase use --add
```

Projenizi seçin: `ai-teacher-project-5eea8`

## Adım 3: Firebase Hosting'i Başlatın

```bash
firebase init hosting
```

Sorulara şöyle cevap verin:
- ✅ Use an existing project → `ai-teacher-project-5eea8` seçin
- ✅ What do you want to use as your public directory? → `build/web` yazın
- ✅ Configure as a single-page app? → `Yes`
- ✅ Set up automatic builds and deploys with GitHub? → `No` (şimdilik)

## Adım 4: Firebase Web App ID Ekleme (ÖNEMLİ!)

1. [Firebase Console](https://console.firebase.google.com/) → Projeniz
2. Project Settings → Your apps → **Web app ekle** (eğer yoksa)
3. App nickname: "AI Teacher Web"
4. **App ID'yi kopyalayın** (format: `1:541014953985:web:xxxxx`)

5. `lib/firebase_options.dart` dosyasını açın ve güncelleyin:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     apiKey: 'AIzaSyBKaWdMwSUWyHo9KsXb1KAjTNZjiBTryUI',
     appId: '1:541014953985:web:GERÇEK_APP_ID_BURAYA', // ← Buraya yapıştırın
     messagingSenderId: '541014953985',
     projectId: 'ai-teacher-project-5eea8',
     authDomain: 'ai-teacher-project-5eea8.firebaseapp.com',
     storageBucket: 'ai-teacher-project-5eea8.firebasestorage.app',
   );
   ```

6. Tekrar build edin:
   ```bash
   flutter build web --release
   ```

## Adım 5: Yayınlayın! 🎉

```bash
firebase deploy --only hosting
```

## ✅ Tamamlandı!

Uygulamanız şu adreste yayında olacak:
**https://ai-teacher-project-5eea8.web.app**

veya

**https://ai-teacher-project-5eea8.firebaseapp.com**

## 🔄 Güncelleme Yapmak İçin

Her değişiklikten sonra:
```bash
flutter build web --release
firebase deploy --only hosting
```

## 📝 Özel Domain Eklemek İçin

1. Firebase Console → Hosting → Add custom domain
2. Domain'inizi ekleyin
3. DNS ayarlarını yapın (Firebase size söyleyecek)

---

**Not:** Firebase Hosting tamamen ücretsizdir ve SSL sertifikası otomatik olarak eklenir!

