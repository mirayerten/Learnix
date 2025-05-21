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

class HomeViewController: UITableViewController {
    
    @IBOutlet weak var motivationLabel: UILabel!
    
    let db = Firestore.firestore()
    var dersler: [UserLessons] = []
    var selectedDers: UserLessons?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        showMotivation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDersler()
    }
    
    private func showMotivation() {
        db.collection("Motivations").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.motivationLabel.text = "Motivasyon yüklenemedi: \(error.localizedDescription)"
                return
            }
            
            let cumleler = snapshot?.documents.compactMap { $0["text"] as? String } ?? []
            self.motivationLabel.text = cumleler.randomElement() ?? "Bugün için ilham verici bir söz bulunamadı."
        }
    }
    
    private func loadDersler() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("Users").document(uid).collection("Lessons").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Hata", message: error.localizedDescription)
                return
            }
            
            self.dersler = snapshot?.documents.compactMap { doc in
                UserLessons(
                    id: doc.documentID,
                    lessonName: doc["lessonName"] as? String ?? "",
                    teacherName: doc["teacherName"] as? String ?? "",
                    pdfURL: doc["pdfURL"] as? String
                )
            } ?? []
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dersler.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeCell", for: indexPath)
        let ders = dersler[indexPath.row]
        cell.textLabel?.text = "📖 \(ders.lessonName)"
        cell.detailTextLabel?.text = "👨‍🏫 \(ders.teacherName)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ders = dersler[indexPath.row]
        
        guard let urlString = ders.pdfURL, !urlString.isEmpty else {
            showAlert(title: "Dosya Yok", message: "Bu derse ait bir PDF dosyası bulunamadı.")
            return
        }
        
        guard urlString.lowercased().hasPrefix("http"), let url = URL(string: urlString) else {
            showAlert(title: "Geçersiz URL", message: "PDF dosyasının URL'si geçerli değil.")
            return
        }
        present(SFSafariViewController(url: url), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let ders = dersler[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            db.collection("Users").document(uid).collection("Lessons").document(ders.id).delete { error in
                if error == nil {
                    self.dersler.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
                completionHandler(true)
            }
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Düzenle") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            self.selectedDers = ders
            self.performSegue(withIdentifier: "editLesson", sender: self)
            completionHandler(true)
        }
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editLesson",
           let destinationVC = segue.destination as? StudentAddLessonViewController {
            destinationVC.ders = selectedDers
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
