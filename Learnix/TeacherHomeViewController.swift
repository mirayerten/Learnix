//
//  TeacherHomeViewController.swift
//  Learnix
//
//  Created by Miray Erten on 19.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SafariServices

struct Lesson {
    let id: String
    let lessonName: String
    let teacherName: String
    let teacherEmail: String
    let pdfURL: String?
}

class TeacherHomeViewController: UITableViewController {

    var lessons: [Lesson] = []
        var selectedLesson: Lesson?
        var currentUserEmail: String?

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.delegate = self
            tableView.dataSource = self
            currentUserEmail = Auth.auth().currentUser?.email
            loadLessons()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            loadLessons()
        }

    private func loadLessons() {
           guard let email = currentUserEmail else { return }

           Firestore.firestore().collection("TeacherLessons")
               .whereField("teacherEmail", isEqualTo: email)
               .getDocuments { [weak self] snapshot, error in
                   guard let self = self else { return }

                   if let error = error {
                       self.showAlert(title: "Hata", message: error.localizedDescription)
                       return
                   }

                   self.lessons = snapshot?.documents.compactMap { doc in
                       let data = doc.data()
                       return Lesson(
                           id: doc.documentID,
                           lessonName: data["lessonName"] as? String ?? "",
                           teacherName: data["teacherName"] as? String ?? "",
                           teacherEmail: data["teacherEmail"] as? String ?? "",
                           pdfURL: data["pdfURL"] as? String  // Burada pdfURL büyük harf duyarlı, firestore alanınla eşleşmeli
                       )
                   } ?? []

                   DispatchQueue.main.async {
                       self.tableView.reloadData()
                   }
               }
       }

        // MARK: - TableView Data Source

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return lessons.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "teacherCell", for: indexPath)
                    let lesson = lessons[indexPath.row]
                    cell.textLabel?.text = lesson.lessonName
                    cell.detailTextLabel?.text = (lesson.pdfURL != nil && !(lesson.pdfURL?.isEmpty ?? true)) ? "📎 PDF var" : "PDF yok"
                    return cell
        }

        // MARK: - TableView Actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let selected = lessons[indexPath.row]

         if let pdfURLString = selected.pdfURL,
            !pdfURLString.isEmpty,
            let url = URL(string: pdfURLString),
            UIApplication.shared.canOpenURL(url) {
             // PDF varsa SafariViewController ile aç
             let safariVC = SFSafariViewController(url: url)
             present(safariVC, animated: true)
         } else {
             // PDF yoksa düzenleme ekranına geç
             if let vc = storyboard?.instantiateViewController(withIdentifier: "TeacherEditLessonViewController") as? TeacherEditLessonViewController {
                 vc.lesson = selected
                 navigationController?.pushViewController(vc, animated: true)
             }
         }
     }

     override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
         let selectedLesson = lessons[indexPath.row]

         let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] _, _, completionHandler in
             guard let self = self else { return }
             Firestore.firestore().collection("TeacherLessons").document(selectedLesson.id).delete { error in
                 if error == nil {
                     self.lessons.remove(at: indexPath.row)
                     tableView.deleteRows(at: [indexPath], with: .fade)
                 }
                 completionHandler(true)
             }
         }

         let editAction = UIContextualAction(style: .normal, title: "Düzenle") { [weak self] _, _, completionHandler in
             guard let self = self else { return }
             self.selectedLesson = selectedLesson
             self.performSegue(withIdentifier: "editLesson", sender: self)
             completionHandler(true)
         }

         editAction.backgroundColor = .systemBlue
         return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
     }

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "editLesson",
            let destinationVC = segue.destination as? TeacherEditLessonViewController {
             destinationVC.lesson = selectedLesson
         }
     }

     private func showAlert(title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "Tamam", style: .default))
         present(alert, animated: true)
     }
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addLesson", sender: nil)
    }
}

