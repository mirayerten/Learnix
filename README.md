# 📚 Learnix

Öğrencilerin ve öğretmenlerin dijital eğitim deneyimini kolaylaştırmak için geliştirilmiş bir iOS uygulamasıdır. Uygulama; ders takibi, görev yönetimi, öğrenme kartları (flashcards) ve daha fazlasını destekler.

## Özellikler

# Öğrenci Paneli
- Kendi derslerini ekleyebilir ve düzenleyebilir.
- Görevlerini takip edebilir (tamamlandı / yapılmadı durumu).
- PDF ders notları ekleyebilir ve görüntüleyebilir.
- Flashcard sistemiyle öğrenmeyi destekler.
- Öğretmen adıyla eklenen ders notlarını görebilir.
- Ana sayfada motivasyon cümlesi ve istatistik özeti görüntülenir.

# Öğretmen Paneli
- Öğretmen rolüyle giriş yapılabilir.
- Kendi derslerini oluşturabilir.
- Tüm öğrencilerle eklediği dersleri paylaşabilir.

# Genel Özellikler
- Rol bazlı kullanıcı girişi mevcut (öğrenci / öğretmen).
- Firebase Authentication ve Firestore entegrasyonu.
- PDF yükleme ve indirme desteği.
- Ortak ayarlar ekranı (tema seçimi, çıkış yapma, kullanıcı bilgileri).

---

## Kurulum Adımları

Aşağıdaki adımları izleyerek uygulamayı çalıştırabilirsiniz:

1. Reponun Kopyalanması
```bash
git clone https://github.com/mirayerten/Learnix.git
cd Learnix
```

2. Xcode ile Projeyi Açın
- `Learnix.xcodeproj` dosyasını çift tıklayarak Xcode'da açın.
- Proje Storyboard tabanlı olarak geliştirildi (UIKit).

3. Firebase Kurulumu
Uygulama Firebase ile kullanılır.

# Gerekli Firebase Servisleri:
- Authentication (Email/Password)
- Firestore Database
- Storage (PDF dosyaları için)

# Firebase Ayarları:
1. Firebase Console'a gidin: https://console.firebase.google.com/
2. Yeni bir proje oluşturun veya mevcut projeyi kullanın.
3. Uygulamayı iOS projesine ekleyin (`com.yourbundle.identifier` gibi).
4. `GoogleService-Info.plist` dosyasını indirin.
5. Xcode'da projenize sağ tıklayarak bu plist dosyasını projeye ekleyin.

4. Gerekli iOS Yetkileri
`Info.plist` dosyasında şu izinlerin tanımlı olduğuna emin olun:
- Firebase kullanımı için internet erişimi.
- PDF gösterimi için gerekli izinler (gerekirse).

---

## Firestore Veri Yapısı

**Kullanıcı Bazlı Yapı:**

```
Users (koleksiyon)
 └── {uid} 
      ├── name: String        
      ├── email: String        
      ├── grade: String        
      ├── school: String      
      ├── role: String       
      ├── photoURL: String     
      ├── Lessons (koleksiyon)
      │     └── {lessonID}
      │          ├── lessonName: String       
      │          ├── teacherName: String   
      │          ├── pdfURL: String        
      ├── Tasks (koleksiyon)
      │     └── {gorevId} 
      │          ├── name: String
      │          ├── dueDate: Timestamp
      │          ├── description: String
      │          ├── isCompleted: Bool (tamamlandı mı?)
      ├── Flashcard (koleksiyon)
      │     └── {flashcardId} 
      │          ├── question: String
      │          ├── answer: String
```

---

`GoogleService-Info.plist` dosyasının doğru projeye ait olduğundan ve `FirebaseApp.configure()` satırının `AppDelegate` içinde tanımlı olduğundan emin olun.
`SceneDelegate` dosyasına kayıtlı tema ayarı ve `AppDelegate` dosyasına bildirim izni ayarı yapmayı unutma.
