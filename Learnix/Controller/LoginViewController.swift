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
    
    @IBAction func loginButton(_ sender: UIButton) {
        loginUser()
    }
    
    @IBAction func registerTappedButton(_ sender: UIButton) {
        performSegue(withIdentifier: "toRegister", sender: self)
    }
    
    private func loginUser() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Eksik Bilgi", message: "Lütfen e-mail ve şifre giriniz.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(title: "Giriş Hatası", message: "E-mail ya da şifre yanlış. Lütfen tekrar deneyin. ")
                return
            }
            self.fetchUserRole(email: email)
        }
    }
    
    private func fetchUserRole(email: String) {
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

            let role = document.data()["role"] as? String ?? ""
            DispatchQueue.main.async {
                switch role {
                case "student":
                    self.performSegue(withIdentifier: "loginToStudentHome", sender: nil)
                case "teacher":
                    self.performSegue(withIdentifier: "loginToTeacherHome", sender: nil)
                default:
                    self.showAlert(title: "Rol Hatası", message: "Kullanıcı rolü tanımlı değil.")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
