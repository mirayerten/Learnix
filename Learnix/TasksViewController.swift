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
    let name: String
    let description: String
    let dueDate: Date
    let isCompleted: Bool
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
                      let isCompleted = data["isCompleted"] as? Bool else {
                    return nil
                }

                return Gorev(name: name, description: description, dueDate: dueTimestamp.dateValue(), isCompleted: isCompleted)
            } ?? []

            self.gorevleriFiltrele()
        }
    }

    func gorevleriFiltrele() {
        let secilenIndex = segmentedControl.selectedSegmentIndex

        if secilenIndex == 0 {
            // Yapılacak görevler (Tamamlanmamış)
            filtreliGorevler = tumGorevler.filter { !$0.isCompleted }
        } else {
            // Tamamlanan görevler
            filtreliGorevler = tumGorevler.filter { $0.isCompleted }
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
               
            return cell
        }
    }
