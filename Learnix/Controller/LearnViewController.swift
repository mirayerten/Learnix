//
//  LearnViewController.swift
//  Learnix
//
//  Created by Miray Erten on 19.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SafariServices

class LearnViewController: UIViewController {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var flashcards: [Flashcard] = []
    private var currentIndex: Int = 0
    private var showingQuestion = true
    
    private var lessons: [TeacherLessons] = []
    private var filteredLessons: [TeacherLessons] = []
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchFlashcards()
    }
    
    private func setupUI() {
        // TableView ve SearchBar delegate & datasource ayarla
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        // Başlangıçta flashcard görünür, liste ve arama gizli
        cardView.isHidden = false
        tableView.isHidden = true
        searchBar.isHidden = true
        
        // Görsellik
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardLabel.isUserInteractionEnabled = true
        cardLabel.addGestureRecognizer(tapGesture)
        
        // Segment değişimini dinle
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
    }
    
    private func fetchFlashcards() {
        guard let currentUser = Auth.auth().currentUser else {
            print("Kullanıcı giriş yapmamış.")
            return
        }
        
        let userID = currentUser.uid
        
        db.collection("Flashcards")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                
                self.flashcards = documents.compactMap {
                    let data = $0.data()
                    guard let question = data["question"] as? String,
                          let answer = data["answer"] as? String,
                          let userID = data["userID"] as? String else { return nil }
                    return Flashcard(id: $0.documentID, question: question, answer: answer, userID: userID)
                }
                DispatchQueue.main.async {
                    self.showFlashcard()
                }
            }
    }
    
    private func showFlashcard() {
        guard !flashcards.isEmpty else {
            cardLabel.text = "Kart yok"
            return
        }
        let flashcard = flashcards[currentIndex]
        cardLabel.text = flashcard.question
        showingQuestion = true
    }
    
    @objc private func flipCard() {
        guard !flashcards.isEmpty else { return }
        let flashcard = flashcards[currentIndex]
        let textToShow = showingQuestion ? flashcard.answer : flashcard.question
        
        UIView.transition(with: cardLabel, duration: 0.5, options: .transitionFlipFromRight) {
            self.cardLabel.text = textToShow
        }
        showingQuestion.toggle()
    }
    
    private func addFlashcard(question: String, answer: String) {
        guard let currentUser = Auth.auth().currentUser else { return }

        let userID = currentUser.uid
        let data: [String: Any] = ["question": question, "answer": answer, "userID": userID]

        db.collection("Flashcards").addDocument(data: data) { error in
            if let error = error {
                print("Ekleme hatası: \(error.localizedDescription)")
            } else {
                self.fetchFlashcards()
            }
        }
    }
    
    private func deleteCurrentFlashcard() {
        guard !flashcards.isEmpty else { return }
        let flashcard = flashcards[currentIndex]
        
        db.collection("Flashcards").document(flashcard.id).delete { error in
            if let error = error {
                print("Kart silme hatası: \(error.localizedDescription)")
            } else {
                self.flashcards.remove(at: self.currentIndex)
                self.currentIndex = max(self.currentIndex - 1, 0)
                self.showFlashcard()
            }
        }
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let isFlashcardSelected = sender.selectedSegmentIndex == 0
        cardView.isHidden = !isFlashcardSelected
        tableView.isHidden = isFlashcardSelected
        searchBar.isHidden = isFlashcardSelected
        
        if !isFlashcardSelected {
            fetchLessons(teacherName: "")
        }
    }
    
    private func fetchLessons(teacherName: String) {
        var query: Query = db.collection("TeacherLessons")
        
        if !teacherName.isEmpty {
            query = query.whereField("teacherName", isEqualTo: teacherName)
        }
        
        query.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Ders çekme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                return
            }
            
            self.lessons = documents.compactMap {
                let data = $0.data()
                let name = data["lessonName"] as? String ?? ""
                let teacher = data["teacherName"] as? String ?? ""
                let pdfURL = data["pdfURL"] as? String
                return TeacherLessons(id: $0.documentID, name: name, teacherName: teacher, pdfURL: pdfURL)
            }
            
            self.filteredLessons = self.lessons
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }
    
    @IBAction func previousTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + flashcards.count) % flashcards.count
        showFlashcard()
    }
    
    @IBAction func nextTapped(_ sender: UIButton) {
        guard !flashcards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % flashcards.count
        showFlashcard()
    }
    
    @IBAction func addTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Yeni Kart", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Soru" }
        alert.addTextField { $0.placeholder = "Cevap" }
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ekle", style: .default) { _ in
            guard let question = alert.textFields?[0].text, !question.isEmpty, let answer = alert.textFields?[1].text, !answer.isEmpty else { return }
            self.addFlashcard(question: question, answer: answer)
        })
        present(alert, animated: true)
    }
    
    @IBAction func deleteTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Sil", message: "Bu kartı silmek istediğine emin misin?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sil", style: .destructive, handler: { _ in
            self.deleteCurrentFlashcard()
        }))
        present(alert, animated: true)
    }
}

extension LearnViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredLessons = lessons
        } else {
            // Hem öğretmen adına hem ders adına göre arama yapmak istiyorsan burada filtreyi güncelle
            filteredLessons = lessons.filter {
                $0.teacherName.lowercased().contains(searchText.lowercased()) ||
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension LearnViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLessons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lesson = filteredLessons[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath)
        cell.textLabel?.text = lesson.name
        cell.detailTextLabel?.text = lesson.teacherName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let lesson = filteredLessons[indexPath.row]
        
        if let urlString = lesson.pdfURL, let url = URL(string: urlString) {
            present(SFSafariViewController(url: url), animated: true)
        } else {
            let alert = UIAlertController(title: "PDF yok", message: "Bu ders için PDF bulunmamaktadır.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }
    }
}
