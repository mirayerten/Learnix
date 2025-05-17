//
//  StudentAddTaskViewController.swift
//  Learnix
//
//  Created by Miray Erten on 17.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth

protocol StudentAddTaskViewControllerDelegate: AnyObject {
    func didAddTask()
}

class StudentAddTaskViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    weak var delegate: StudentAddTaskViewControllerDelegate?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.cornerRadius = 8
        
        // Delegateleri ayarla
                nameTextField.delegate = self
                descriptionTextView.delegate = self

                // TextView için done butonlu toolbar ekle
                addDoneButtonOnKeyboard()
    }
    
    // TextView için toolbar ve tamam butonu
        private func addDoneButtonOnKeyboard() {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()

            let doneButton = UIBarButtonItem(title: "Tamam", style: .plain, target: self, action: #selector(dismissKeyboard))
            toolbar.items = [doneButton]

            descriptionTextView.inputAccessoryView = toolbar
        }

        @objc private func dismissKeyboard() {
            view.endEditing(true)
        }

        // Boş bir alana dokunulduğunda klavyeyi kapat
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            dismissKeyboard()
        }


    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        guard let name = nameTextField.text, !name.isEmpty,
              let description = descriptionTextView.text, !description.isEmpty else {
            showAlert("Lütfen tüm alanları doldurunuz.")
            return
        }

        let dueDate = datePicker.date

        let taskData: [String: Any] = [
            "name": name,
            "description": description,
            "dueDate": Timestamp(date: dueDate),
            "isCompleted": false
        ]

        Firestore.firestore()
            .collection("Users")
            .document(userID)
            .collection("Tasks")
            .addDocument(data: taskData) { error in
                if let error = error {
                    self.showAlert("Görev kaydedilemedi: \(error.localizedDescription)")
                } else {
                    self.delegate?.didAddTask() // 🔥 Delegate tetikleniyor
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
