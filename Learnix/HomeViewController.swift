//
//  HomeViewController.swift
//  Learnix
//
//  Created by Miray Erten on 16.05.2025.
//

import UIKit
import Firebase
import FirebaseFirestore
import SafariServices

struct Ders {
    let name: String
    let pdfURL: String?
}

class HomeViewController: UITableViewController {

    @IBOutlet weak var motivationLabel: UILabel!
    
    var dersler: [Ders] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        showMotivation()
        loadDersler()
    }

    func showMotivation() {
        let db = Firestore.firestore()
        db.collection("Motivations").getDocuments { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.motivationLabel.text = "Motivasyon yüklenemedi."
                    print("Motivasyon verisi çekilemedi: \(error.localizedDescription)")
                }
                return
            }

            let cumleler = snapshot?.documents.compactMap { $0["text"] as? String } ?? []
            if let rastgele = cumleler.randomElement() {
                DispatchQueue.main.async {
                    self.motivationLabel.text = rastgele
                }
            } else {
                DispatchQueue.main.async {
                    self.motivationLabel.text = "Bugün için ilham verici bir söz bulunamadı."
                }
            }
        }
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
            
            self.dersler = snapshot?.documents.compactMap { doc in
                let name = doc["name"] as? String ?? ""
                let pdfURL = doc["pdfURL"] as? String
                return Ders(name: name, pdfURL: pdfURL)
            } ?? []
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dersler.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeCell", for: indexPath)
        cell.textLabel?.text = dersler[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDers = dersler[indexPath.row]

        guard let urlString = selectedDers.pdfURL, let url = URL(string: urlString) else {
            let alert = UIAlertController(title: "Dosya Yok", message: "Bu derse ait bir PDF dosyası bulunamadı.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }

        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}
