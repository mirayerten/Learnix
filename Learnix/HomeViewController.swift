//
//  HomeViewController.swift
//  Learnix
//
//  Created by Miray Erten on 16.05.2025.
//

import UIKit
import Firebase
import FirebaseFirestore

class HomeViewController: UITableViewController {

    @IBOutlet weak var motivationLabel: UILabel!
    
    var dersler: [String] = []
       
    var motivationQuotes = [
        "Bugün harika bir gün olacak!",
        "Her gün yeni bir başlangıçtır.",
        "Küçük adımlar büyük farklar yaratır.",
        "Pes etme, başarı yakında!"
    ]
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dersler.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeCell", for: indexPath)
        cell.textLabel?.text = dersler[indexPath.row]
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        showMotivation()
        loadDersler()
    }

    func showMotivation() {
        motivationLabel.text = motivationQuotes.randomElement()
    }

    func loadDersler() {
        let db = Firestore.firestore()
        db.collection("Dersler").getDocuments { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Hata", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self.present(alert, animated: true)
                }
                return
            }
            self.dersler = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}
