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
            } else {
                self.performSegue(withIdentifier: "loginToHome", sender: nil)
            
                return
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

