//
//  StudentSettingsViewController.swift
//  Learnix
//
//  Created by Miray Erten on 20.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth

class SettingsTableViewController: UITableViewController {
    
    let settings = ["Kullanıcı Ayarları", "Şifre Değiştir", "Tema", "Çıkış Yap"]
        var role: String = ""

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Ayarlar"
            role = UserDefaults.standard.string(forKey: "userRole") ?? ""
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return settings.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
            cell.textLabel?.text = settings[indexPath.row]
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

        func showChangePasswordAlert() {
            let alert = UIAlertController(title: "Şifre Değiştir", message: nil, preferredStyle: .alert)
            
            alert.addTextField { $0.placeholder = "Mevcut şifre"; $0.isSecureTextEntry = true }
            alert.addTextField { $0.placeholder = "Yeni şifre"; $0.isSecureTextEntry = true }

            let changeAction = UIAlertAction(title: "Değiştir", style: .default) { _ in
                guard let currentPassword = alert.textFields?[0].text,
                      let newPassword = alert.textFields?[1].text,
                      !currentPassword.isEmpty, !newPassword.isEmpty else {
                    self.showAlert(title: "Hata", message: "Tüm alanları doldurmalısınız.")
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
                showAlert(title: "Hata", message: "Kullanıcı bilgileri alınamadı.")
                return
            }

            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

            user.reauthenticate(with: credential) { _, error in
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
                self.setTheme(.light)
            }))
            alert.addAction(UIAlertAction(title: "Koyu Mod", style: .default, handler: { _ in
                self.setTheme(.dark)
            }))
            alert.addAction(UIAlertAction(title: "Sistem Varsayılanı", style: .default, handler: { _ in
                self.setTheme(.unspecified)
            }))
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
