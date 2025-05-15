//
//  RegisterViewController.swift
//  Learnix
//
//  Created by Miray Erten on 14.05.2025.
//

import UIKit
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
            showAlert(title: "Eksik bilgi", message: "Lütfen e-mail ve şifre giriniz.")
            return
        }
        
        Auth.auth().signIn(withEmail: registerEmailTextField.text!, password: registerPasswordTextField.text!) { authdata, error in
            if let error = error {
                self.showAlert(title: "Kayıt hatası", message: error.localizedDescription)
            }
            self.showAlert(title: "Başarılı", message: "Kayıt oldunuz.")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Tamam", style: .default)
        alert.addAction(alertAction)
        self.present(alert, animated: true, completion: nil)
    }

}
//
