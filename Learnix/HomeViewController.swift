//
//  HomeViewController.swift
//  Learnix
//
//  Created by Miray Erten on 16.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SafariServices

struct Ders {
    let id: String
    let lessonName: String
    let teacherName: String
    let pdfURL: String?
}

class HomeViewController: UITableViewController {

    @IBOutlet weak var motivationLabel: UILabel!
    
    var dersler: [Ders] = []
    var selectedDers: Ders?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        showMotivation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDersler()
      //  fetchDersler()
    }

    private func showMotivation() {
        let db = Firestore.firestore()
        db.collection("Motivations").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if error != nil {
                DispatchQueue.main.async {
                    self.motivationLabel.text = "Motivasyon yüklenemedi."
                }
                return
            }

            let cumleler = snapshot?.documents.compactMap { $0["text"] as? String } ?? []
            DispatchQueue.main.async {
                self.motivationLabel.text = cumleler.randomElement() ?? "Bugün için ilham verici bir söz bulunamadı."
            }
        }
    }

    private func loadDersler() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

            let db = Firestore.firestore()
            db.collection("Users").document(uid).collection("Lessons").getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Hata", message: error.localizedDescription)
                    }
                    return
                }

                self.dersler = snapshot?.documents.compactMap { doc in
                    Ders(
                        id: doc.documentID,
                        lessonName: doc["lessonName"] as? String ?? "",
                        teacherName: doc["teacherName"] as? String ?? "",
                        pdfURL: doc["pdfURL"] as? String
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    
  /*  private func fetchDersler() {
        let db = Firestore.firestore()
        db.collection("Dersler").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if error != nil { return }
            
            self.dersler = snapshot?.documents.compactMap { document in
                let data = document.data()
                let id = document.documentID
                let lessonName = data["lessonName"] as? String ?? ""
                let teacherName = data["teacherName"] as? String ?? ""
                let pdfUrl = data["pdfUrl"] as? String
                
                return Ders(id: id, lessonName: lessonName, teacherName: teacherName, pdfURL: pdfUrl)
            } ?? []
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    } */
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dersler.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "homeCell", for: indexPath)
        let ders = dersler[indexPath.row]
        
        cell.textLabel?.text = ders.lessonName
        cell.detailTextLabel?.text = "👨‍🏫 \(ders.teacherName)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDers = dersler[indexPath.row]
        
     /*   guard let urlString = selectedDers.pdfURL,
                     !urlString.isEmpty,
                     let url = URL(string: urlString),
                     url.scheme?.contains("http") == true else {
                   showAlert(title: "Hata", message: "PDF bağlantısı geçerli değil.")
                   return
               } */

        guard let urlString = selectedDers.pdfURL, !urlString.isEmpty else {
            showAlert(title: "Dosya Yok", message: "Bu derse ait bir PDF dosyası bulunamadı.")
            return
        }

        guard urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") else {
            showAlert(title: "Geçersiz URL", message: "PDF dosyasının URL'si geçerli değil.")
            return
        }

        guard let url = URL(string: urlString) else {
            showAlert(title: "Hata", message: "URL oluşturulamadı.")
            return
        }

        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let selectedDers = dersler[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let db = Firestore.firestore()
            db.collection("Users").document(uid).collection("Lessons").document(selectedDers.id).delete { error in
                if error == nil {
                    self.dersler.remove(at: indexPath.row)
                    DispatchQueue.main.async {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
                completionHandler(true)
            }
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Düzenle") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            self.selectedDers = selectedDers
            self.performSegue(withIdentifier: "editLesson", sender: self)
            completionHandler(true)
        }
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editLesson",
           let destinationVC = segue.destination as? StudentEditLessonViewController {
            destinationVC.ders = selectedDers
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
