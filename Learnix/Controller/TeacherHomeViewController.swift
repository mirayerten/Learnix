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

class TeacherHomeViewController: UITableViewController {
    
    var lessons: [Lesson] = []
    var selectedLesson: Lesson?
    var currentUserEmail: String?{
        return Auth.auth().currentUser?.email
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadLessons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLessons()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "teacherCell", for: indexPath)
        let lesson = lessons[indexPath.row]
        cell.textLabel?.text = lesson.lessonName
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let hasPDF = lesson.pdfURL?.isEmpty == false
        cell.detailTextLabel?.text = hasPDF ? "PDF mevcut 📎" : "PDF yok"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = lessons[indexPath.row]
        
        if let pdfURLString = selected.pdfURL,
           let url = URL(string: pdfURLString),
           UIApplication.shared.canOpenURL(url) {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        } else {
            showEditScreen(with: selected)
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let lesson = lessons[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] _, _, completionHandler in
            self?.deleteLesson(lesson, at: indexPath, completion: completionHandler)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Düzenle") { [weak self] _, _, completionHandler in
            self?.selectedLesson = lesson
            self?.performSegue(withIdentifier: "editLesson", sender: self)
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
                        pdfURL: data["pdfURL"] as? String
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    private func showEditScreen(with lesson: Lesson) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "TeacherEditLessonViewController") as? TeacherEditLessonViewController {
            vc.lesson = lesson
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func deleteLesson(_ lesson: Lesson, at indexPath: IndexPath, completion: @escaping (Bool) -> Void) {
        Firestore.firestore().collection("TeacherLessons").document(lesson.id).delete { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.lessons.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                self.showAlert(title: "Hata", message: "Silme işlemi başarısız.")
            }
            completion(true)
        }
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addLesson", sender: nil)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
