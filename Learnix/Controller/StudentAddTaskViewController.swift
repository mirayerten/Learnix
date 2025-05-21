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
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let db = Firestore.firestore()
    weak var delegate: StudentAddTaskViewControllerDelegate?
    var isEditingTask = false
    var taskToEdit: Gorev?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureTextInputs()
        loadTaskIfEditing()
    }
    
    private func configureUI() {
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.cornerRadius = 8
        
        datePicker.minimumDate = Date()
        datePicker.layer.cornerRadius = 8
    }
    
    private func configureTextInputs() {
        nameTextField.delegate = self
        descriptionTextView.delegate = self
        addDoneButtonToKeyboard()
    }
    
    private func addDoneButtonToKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Tamam", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexSpace, doneButton]
        
        nameTextField.inputAccessoryView = toolbar
        descriptionTextView.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func loadTaskIfEditing() {
        if isEditingTask, let task = taskToEdit {
            nameTextField.text = task.name
            descriptionTextView.text = task.description
            datePicker.date = task.dueDate
        }
    }
    
    private func saveTask() {
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
        
        let userTasksRef = db.collection("Users").document(userID).collection("Tasks")
        
        if isEditingTask, let taskID = taskToEdit?.id {
            userTasksRef.document(taskID).updateData(taskData) { error in
                self.handleFirestoreResponse(error, isEdit: true)
            }
        } else {
            userTasksRef.addDocument(data: taskData) { error in
                self.handleFirestoreResponse(error, isEdit: false)
            }
        }
        scheduleNotification(taskName: name, dueDate: dueDate)
    }
    
    private func handleFirestoreResponse(_ error: Error?, isEdit: Bool) {
        if let error = error {
            let message = isEdit ? "Görev güncellenemedi" : "Görev kaydedilemedi"
            showAlert("\(message): \(error.localizedDescription)")
        } else {
            delegate?.didAddTask()
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func scheduleNotification(taskName: String, dueDate: Date) {
        guard let notificationDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate),
              notificationDate > Date() else {
            return // Bildirim tarihi geçmişse gönderme
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Görev Hatırlatması"
        content.body = "\(taskName) görevinizin yarın teslim zamanı."
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        saveTask()
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Uyarı", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    // Klavyeyi ekranın boş bir yerine tıklayınca kapat
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissKeyboard()
    }
}
