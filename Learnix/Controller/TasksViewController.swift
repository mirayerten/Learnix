//
//  TasksViewController.swift
//  Learnix
//
//  Created by Miray Erten on 16.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class TasksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StudentAddTaskViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var tumGorevler: [Gorev] = []
    var filtreliGorevler: [Gorev] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadGorevler()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtreliGorevler.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = filtreliGorevler[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "tasksCell", for: indexPath)
        cell.textLabel?.text = task.name
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        cell.detailTextLabel?.text = formatter.string(from: task.dueDate)
        
        switch task.status {
        case "Yapılacak":
            cell.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        case "Yapılıyor":
            cell.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.1)
        case "Tamamlandı":
            cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        default:
            cell.backgroundColor = .white
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = filtreliGorevler[indexPath.row]
        var actions: [UIContextualAction] = []
        
        if task.status != "Tamamlandı" {
            let completeAction = UIContextualAction(style: .normal, title: "Tamamlandı") { _, _, completion in
                self.updateTaskStatus(taskID: task.id, newStatus: "Tamamlandı")
                completion(true)
            }
            completeAction.backgroundColor = .systemGreen
            actions.append(completeAction)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Düzenle") { _, _, completion in
            self.performSegue(withIdentifier: "editTask", sender: task)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        actions.append(editAction)
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { _, _, completion in
            self.deleteTask(id: task.id)
            completion(true)
        }
        actions.append(deleteAction)
        
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? StudentAddTaskViewController else { return }
        
        destinationVC.delegate = self
        
        if segue.identifier == "addTask" {
            destinationVC.isEditingTask = false
        } else if segue.identifier == "editTask", let task = sender as? Gorev {
            destinationVC.isEditingTask = true
            destinationVC.taskToEdit = task
        }
    }
    
    func didAddTask() {
        loadGorevler()
    }
    
    private func loadGorevler() {
        guard let userID = Auth.auth().currentUser?.uid else {
            showError("Kullanıcı bulunamadı.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Users").document(userID).collection("Tasks").getDocuments { snapshot, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }
            
            self.tumGorevler = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let dueTimestamp = data["dueDate"] as? Timestamp,
                      let status = data["status"] as? String else {
                    return nil
                }
                
                return Gorev(
                    id: doc.documentID,
                    name: name,
                    description: description,
                    dueDate: dueTimestamp.dateValue(),
                    status: status
                )
            } ?? []
            self.filterTasks()
        }
    }
    
    private func filterTasks() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            filtreliGorevler = tumGorevler.filter { $0.status == "Yapılacak" }
        case 1:
            filtreliGorevler = tumGorevler.filter { $0.status == "Tamamlandı" }
        default:
            filtreliGorevler = tumGorevler
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    
    private func updateTaskStatus(taskID: String, newStatus: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("Users").document(userID).collection("Tasks").document(taskID).updateData([
            "status": newStatus
        ]) { error in
            if let error = error {
                print("Statü güncellenemedi: \(error.localizedDescription)")
            }
            self.loadGorevler()
        }
    }
    
    private func deleteTask(id: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("Users").document(userID).collection("Tasks").document(id).delete { error in
            if let error = error {
                print("Görev silinemedi: \(error.localizedDescription)")
            }
            self.loadGorevler()
        }
    }
    
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addTask", sender: self)
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        filterTasks()
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
