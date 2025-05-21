//
//  SettingsViewController.swift
//  Learnix
//
//  Created by Miray Erten on 21.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let settings = ["Kullanıcı Ayarları", "Şifre Değiştir", "Tema", "Çıkış Yap"]
    var role: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ayarlar"
        role = UserDefaults.standard.string(forKey: "userRole") ?? ""
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView() // boş hücreleri kaldırır
        
        // Profil resmi yuvarlak olsun
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        loadUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfile()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        cell.textLabel?.text = settings[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: role == "student" ? "toStudentUser" : "toTeacherUser", sender: nil)
        case 1:
            showChangePasswordAlert()
        case 2:
            showThemeOptions()
        case 3:
            logoutUser()
        default:
            break
        }
    }

    func loadUserProfile() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(userID)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Firestore document alınırken hata: \(error.localizedDescription)")
                self.showAlert(title: "Hata", message: "Kullanıcı verileri alınamadı")
                return
            }
            guard let document = document, document.exists, let data = document.data() else {
                self.showAlert(title: "Hata", message: "Kullanıcı verileri bulunamadı")
                return
            }
            
            DispatchQueue.main.async {
                self.profileNameLabel.text = data["name"] as? String ?? "Ad gözükmüyor"
            }
            
            if let profileImageUrl = data["photoURL"] as? String {
                print("Gelen profil image URL: \(profileImageUrl)")
                self.loadProfileImage(from: profileImageUrl)
            } else {
                DispatchQueue.main.async {
                    self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                }
            }
        }
    }
    
    func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Profil resmi URL'si geçersiz: \(urlString)")
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Profil fotoğrafı indirme hatası: \(error.localizedDescription)")
                return
            }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            }
        }.resume()
    }
    
    func updateUserProfileImageURL(_ urlString: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("Users").document(uid).updateData(["photoURL": urlString]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Hata", message: "Profil resmi güncellenemedi: \(error.localizedDescription)")
                } else {
                    // Profil resmi güncellendi, bildirimi gönder:
                    NotificationCenter.default.post(name: Notification.Name("ProfileImageUpdated"), object: nil, userInfo: ["url": urlString])
                }
            }
        }
    }

    func showChangePasswordAlert() {
        let alert = UIAlertController(title: "Şifre Değiştir", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Mevcut şifre"; $0.isSecureTextEntry = true }
        alert.addTextField { $0.placeholder = "Yeni şifre"; $0.isSecureTextEntry = true }
        
        let changeAction = UIAlertAction(title: "Değiştir", style: .default) { _ in
            guard let currentPassword = alert.textFields?[0].text,
                  let newPassword = alert.textFields?[1].text,
                  !currentPassword.isEmpty, !newPassword.isEmpty else {
                self.showAlert(title: "Hata", message: "Tüm alanları doldurun.")
                return
            }
            self.reauthenticateAndChangePassword(currentPassword: currentPassword, newPassword: newPassword)
        }
        
        alert.addAction(changeAction)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
    
    func reauthenticateAndChangePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            showAlert(title: "Hata", message: "Kullanıcı bilgisi alınamadı.")
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                self.showAlert(title: "Hata", message: "Kimlik doğrulama başarısız: \(error.localizedDescription)")
            } else {
                user.updatePassword(to: newPassword) { error in
                    if let error = error {
                        self.showAlert(title: "Hata", message: "Şifre değiştirilemedi: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "Başarılı", message: "Şifre başarıyla değiştirildi.")
                    }
                }
            }
        }
    }
    
    func showThemeOptions() {
        let alert = UIAlertController(title: "Tema", message: "Tema seçiniz", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Açık Mod", style: .default) { _ in self.setTheme(.light) })
        alert.addAction(UIAlertAction(title: "Koyu Mod", style: .default) { _ in self.setTheme(.dark) })
        alert.addAction(UIAlertAction(title: "Sistem Varsayılanı", style: .default) { _ in self.setTheme(.unspecified) })
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
    
    func setTheme(_ style: UIUserInterfaceStyle) {
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "appTheme")
    }
    
    func logoutUser() {
        do {
            try Auth.auth().signOut()
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.switchToLogin()
            }
        } catch {
            showAlert(title: "Hata", message: "Çıkış yapılamadı: \(error.localizedDescription)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alertVC, animated: true)
    }
}
