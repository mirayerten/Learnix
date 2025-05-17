//
//  TasksViewController.swift
//  Learnix
//
//  Created by Miray Erten on 16.05.2025.
//

import UIKit
import Firebase
import FirebaseFirestore

struct Gorev {
    let title: String
    let status: String
    let dueDate: Date
}

class TasksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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

        func loadGorevler() {
            let db = Firestore.firestore()
            db.collection("Gorevler").getDocuments { snapshot, error in
                if let error = error {
                    self.gosterHataMesaji(error.localizedDescription)
                    return
                }

                self.tumGorevler = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let status = data["status"] as? String,
                          let dueTimestamp = data["dueDate"] as? Timestamp else {
                        return nil
                    }

                    return Gorev(title: title, status: status, dueDate: dueTimestamp.dateValue())
                } ?? []

                self.gorevleriFiltrele()
            }
        }

        func gorevleriFiltrele() {
            let secilenIndex = segmentedControl.selectedSegmentIndex
            let secilenDurum = segmentedControl.titleForSegment(at: secilenIndex) ?? "Yapılacak"

            filtreliGorevler = tumGorevler.filter { $0.status == secilenDurum }
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

        // MARK: - TableView DataSource

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filtreliGorevler.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tasksCell", for: indexPath)
               
               let gorev = filtreliGorevler[indexPath.row]
               cell.textLabel?.text = gorev.title

               let formatter = DateFormatter()
               formatter.dateStyle = .short
               formatter.timeStyle = .none
               cell.detailTextLabel?.text = formatter.string(from: gorev.dueDate)
               
               return cell
        }
    }
