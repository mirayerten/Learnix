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

struct Gorev {
    let id: String
    let name: String
    let description: String
    let dueDate: Date
    let status: String
}

class TasksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StudentAddTaskViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var tumGorevler: [Gorev] = []
    var filtreliGorevler: [Gorev] = []

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.delegate = self
            tableView.dataSource = self

            // Custom cell register edilmeli (Storyboard'dan yapılmadıysa)
            // tableView.register(UINib(nibName: "TasksCell", bundle: nil), forCellReuseIdentifier: "tasksCell")

            loadGorevler()
            
        }
    
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addTask", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addTask" {
            if let destinationVC = segue.destination as? StudentAddTaskViewController {
                destinationVC.delegate = self
                destinationVC.isEditingTask = false
            }
        } else if segue.identifier == "editTask" {
            if let destinationVC = segue.destination as? StudentAddTaskViewController, let gorev = sender as? Gorev {
                destinationVC.delegate = self
                destinationVC.isEditingTask = true
                destinationVC.taskToEdit = gorev
            }
        }
    }
    
    func didAddTask() {
        loadGorevler()
    }

    func loadGorevler() {
            guard let userID = Auth.auth().currentUser?.uid else {
                gosterHataMesaji("Kullanıcı bulunamadı.")
                return
            }

            let db = Firestore.firestore()
            db.collection("Users").document(userID).collection("Tasks").getDocuments { snapshot, error in
                if let error = error {
                    self.gosterHataMesaji(error.localizedDescription)
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

                self.gorevleriFiltrele()
            }
        }

    func gorevleriFiltrele() {
            let secilenIndex = segmentedControl.selectedSegmentIndex

            switch secilenIndex {
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

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        gorevleriFiltrele()
    }

    func gosterHataMesaji(_ mesaj: String) {
            let alert = UIAlertController(title: "Hata", message: mesaj, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filtreliGorevler.count
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tasksCell", for: indexPath)
            let gorev = filtreliGorevler[indexPath.row]

            cell.textLabel?.text = gorev.name

            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            cell.detailTextLabel?.text = formatter.string(from: gorev.dueDate)

            // Hücre rengi: statüye göre
            switch gorev.status {
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

        // MARK: - Swipe Actions

        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

            let gorev = filtreliGorevler[indexPath.row]
            var actions: [UIContextualAction] = []

            if gorev.status != "Tamamlandı" {
                let tamamlaAction = UIContextualAction(style: .normal, title: "Tamamlandı") { _, _, completion in
                    self.updateTaskStatus(gorevID: gorev.id, newStatus: "Tamamlandı")
                    completion(true)
                }
                tamamlaAction.backgroundColor = .systemGreen
                actions.append(tamamlaAction)
            }
            
            // Düzenle butonu ekliyoruz
                let duzenleAction = UIContextualAction(style: .normal, title: "Düzenle") { _, _, completion in
                    self.performSegue(withIdentifier: "editTask", sender: gorev)
                    completion(true)
                }
                duzenleAction.backgroundColor = .systemBlue
                actions.append(duzenleAction)

            let silAction = UIContextualAction(style: .destructive, title: "Sil") { _, _, completion in
                self.silGorev(id: gorev.id)
                completion(true)
            }
            actions.append(silAction)

            return UISwipeActionsConfiguration(actions: actions)
        }

        func updateTaskStatus(gorevID: String, newStatus: String) {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("Users").document(userID).collection("Tasks").document(gorevID).updateData([
                "status": newStatus
            ]) { error in
                if let error = error {
                    print("Statü güncellenemedi: \(error.localizedDescription)")
                    return
                }
                self.loadGorevler()
            }
        }

        func silGorev(id: String) {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("Users").document(userID).collection("Tasks").document(id).delete { error in
                if let error = error {
                    print("Görev silinemedi: \(error.localizedDescription)")
                } else {
                    self.loadGorevler()
                }
            }
        }
    }
