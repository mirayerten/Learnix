//
//  RegisterViewController.swift
//  Learnix
//
//  Created by Miray Erten on 14.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var registerLabel: UILabel!
    @IBOutlet weak var registerEmailTextField: UITextField!
    @IBOutlet weak var registerPasswordTextField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func registerButton(_ sender: UIButton) {
        guard let email = registerEmailTextField.text, !email.isEmpty,
                      let password = registerPasswordTextField.text, !password.isEmpty else {
            showAlert(title: "Eksik Bilgi", message: "Lütfen e-posta ve şifre giriniz.")
                    return
                }

                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        self.showAlert(title: "Olmadı", message: "Kayıt başarısız: \(error.localizedDescription)")
                        return
                    }
                    // Kayıt başarılı, segue ile geç
                    self.performSegue(withIdentifier: "registerToHome", sender: self)
                }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Tamam", style: .default)
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: nil)
    }

}
