//
//  StudentSettingsViewController.swift
//  Learnix
//
//  Created by Miray Erten on 20.05.2025.
//

import UIKit
import FirebaseAuth

class StudentSettingsViewController: UITableViewController {


    let settings = ["Kullanıcı Ayarları", "Şifre Değiştir", "Tema", "Çıkış Yap"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ayarlar"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        cell.textLabel?.text = settings[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            // Kullanıcı Ayarları
            navigateToUserSettings()
        case 1:
            // Şifre Değiştir
            showChangePasswordAlert()
        case 2:
            // Tema
            showThemeOptions()
        case 3:
            // Çıkış Yap
            logoutUser()
        default:
            break
        }
    }

    // MARK: - Navigasyon Fonksiyonları

    func navigateToUserSettings() {
        performSegue(withIdentifier: "toUser", sender: nil)
    }

    /*func showPasswordResetAlert() {
        let alert = UIAlertController(title: "Şifre Sıfırlama", message: "Şifre sıfırlama e-postası göndermek istiyor musunuz?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Gönder", style: .default, handler: { _ in
            self.sendPasswordReset()
        }))
        present(alert, animated: true)
    }

    func sendPasswordReset() {
        guard let email = Auth.auth().currentUser?.email else {
            showAlert(title: "Hata", message: "Kullanıcı e-postası bulunamadı.")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.showAlert(title: "Hata", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Başarılı", message: "Şifre sıfırlama e-postası gönderildi.")
            }
        }
    }*/
    
    func showChangePasswordAlert() {
        let alert = UIAlertController(title: "Şifre Değiştir", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Mevcut şifre"
            textField.isSecureTextEntry = true
        }

        alert.addTextField { textField in
            textField.placeholder = "Yeni şifre"
            textField.isSecureTextEntry = true
        }

        let changeAction = UIAlertAction(title: "Değiştir", style: .default) { _ in
            guard let currentPassword = alert.textFields?[0].text,
                  let newPassword = alert.textFields?[1].text,
                  !currentPassword.isEmpty, !newPassword.isEmpty else {
                self.showAlert(title: "Hata", message: "Tüm alanları doldurmalısınız.")
                return
            }

            self.reauthenticateAndChangePassword(currentPassword: currentPassword, newPassword: newPassword)
        }

        let cancelAction = UIAlertAction(title: "İptal", style: .cancel, handler: nil)

        alert.addAction(changeAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
    
    func reauthenticateAndChangePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            showAlert(title: "Hata", message: "Kullanıcı bilgileri alınamadı.")
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                self.showAlert(title: "Hata", message: "Kimlik doğrulama başarısız: \(error.localizedDescription)")
            } else {
                user.updatePassword(to: newPassword) { error in
                    if let error = error {
                        self.showAlert(title: "Hata", message: "Şifre güncellenemedi: \(error.localizedDescription)")
                    } else {
                        self.showAlert(title: "Başarılı", message: "Şifreniz başarıyla değiştirildi.")
                    }
                }
            }
        }
    }

    func showThemeOptions() {
        let alert = UIAlertController(title: "Tema", message: "Tema seçiniz", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Açık Mod", style: .default, handler: { _ in
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        }))
        alert.addAction(UIAlertAction(title: "Koyu Mod", style: .default, handler: { _ in
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        }))
        alert.addAction(UIAlertAction(title: "Sistem Varsayılanı", style: .default, handler: { _ in
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
        }))
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }

    func logoutUser() {
        do {
            try Auth.auth().signOut()
            // Giriş ekranına yönlendir
            if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
                sceneDelegate.switchToLogin()
            }
        } catch {
            showAlert(title: "Hata", message: "Çıkış yapılamadı: \(error.localizedDescription)")
        }
    }

    // MARK: - Yardımcı Alert Fonksiyonu
    func showAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alertVC, animated: true)
    }
}
