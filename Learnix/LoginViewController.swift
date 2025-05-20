//
//  ViewController.swift
//  Learnix
//
//  Created by Miray Erten on 14.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var queryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
  /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Auth.auth().currentUser != nil {
            // Oturum açık, direkt ana sayfaya
            performSegue(withIdentifier: "goToMain", sender: nil)
        }
    }
*/
    
    @IBAction func loginButton(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                showAlert(title: "Eksik Bilgi", message: "Lütfen e-posta ve şifre girin.")
                return
            }

            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.showAlert(title: "Giriş Hatası", message: error.localizedDescription)
                    return
                }

                // Giriş başarılıysa kullanıcı rolünü Firestore'dan al
                let db = Firestore.firestore()
                db.collection("Users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                    if let error = error {
                        self.showAlert(title: "Hata", message: error.localizedDescription)
                        return
                    }

                    guard let document = snapshot?.documents.first else {
                        self.showAlert(title: "Hata", message: "Kullanıcı bilgisi bulunamadı.")
                        return
                    }

                    let data = document.data()
                    let role = data["role"] as? String ?? ""

                    DispatchQueue.main.async {
                        if role == "student" {
                            self.performSegue(withIdentifier: "loginToStudentHome", sender: nil)
                        } else if role == "teacher" {
                            self.performSegue(withIdentifier: "loginToTeacherHome", sender: nil)
                        } else {
                            self.showAlert(title: "Rol Hatası", message: "Kullanıcı rolü tanımlı değil.")
                        }
                    }
                }
            }
        }
    
    @IBAction func registerTappedButton(_ sender: UIButton) {
        performSegue(withIdentifier: "toRegister", sender: self)
    }
    
    private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }
    
}

