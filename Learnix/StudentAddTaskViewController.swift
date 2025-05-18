//
//  StudentAddTaskViewController.swift
//  Learnix
//
//  Created by Miray Erten on 17.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import UserNotifications

protocol StudentAddTaskViewControllerDelegate: AnyObject {
    func didAddTask()
}

class StudentAddTaskViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    weak var delegate: StudentAddTaskViewControllerDelegate?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var isEditingTask = false
    var taskToEdit: Gorev?
    
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
        
        datePicker.minimumDate = Date() // geçmiş tarih seçmesin
        
        if isEditingTask, let task = taskToEdit {
                nameTextField.text = task.name
                descriptionTextView.text = task.description
                datePicker.date = task.dueDate
            }
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
            "status": "Yapılacak"
        ]

        let db = Firestore.firestore()
            if isEditingTask, let taskID = taskToEdit?.id {
                // Güncelle
                db.collection("Users").document(userID).collection("Tasks").document(taskID).updateData(taskData) { error in
                    if let error = error {
                        self.showAlert("Görev güncellenemedi: \(error.localizedDescription)")
                    } else {
                        self.delegate?.didAddTask()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else {
                // Yeni ekle
                db.collection("Users").document(userID).collection("Tasks").addDocument(data: taskData) { error in
                    if let error = error {
                        self.showAlert("Görev kaydedilemedi: \(error.localizedDescription)")
                    } else {
                        self.delegate?.didAddTask()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    
    func scheduleNotification(taskName: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Görev Hatırlatması"
        content.body = "\(taskName) göreviniz yarın teslim zamanı."
        content.sound = .default

        guard let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) else {
            return
        }

        if notificationDate < Date() {
            // Bildirim tarihi geçmiş, planlama yapma
            return
        }

        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim planlanamadı: \(error.localizedDescription)")
            } else {
                print("Bildirim planlandı.")
            }
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
