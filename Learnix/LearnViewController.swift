//
//  LearnViewController.swift
//  Learnix
//
//  Created by Miray Erten on 19.05.2025.
//

import UIKit
import Firebase
import FirebaseFirestore

struct Flashcard {
    let id: String
    let question: String
    let answer: String
    let userID: String
}


class LearnViewController: UIViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    
    var flashcards: [Flashcard] = []
    var currentIndex: Int = 0
    var showingQuestion = true
    let userID = "testUser123" // Giriş yapan kullanıcıya göre değiştir

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFlashcards()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardLabel.isUserInteractionEnabled = true
        cardLabel.addGestureRecognizer(tapGesture)
        // Görsellik
           cardView.layer.cornerRadius = 12
           cardView.layer.shadowColor = UIColor.black.cgColor
           cardView.layer.shadowOpacity = 0.2
           cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
           cardView.layer.shadowRadius = 4
    }
    
    func fetchFlashcards() {
        let db = Firestore.firestore()
        db.collection("Flashcards").whereField("userID", isEqualTo: userID).getDocuments { snapshot, error in
            guard error == nil else {
                print("Error fetching: \(error!)")
                return
            }
            self.flashcards = snapshot?.documents.compactMap {
                let data = $0.data()
                guard let question = data["question"] as? String,
                      let answer = data["answer"] as? String,
                      let userID = data["userID"] as? String else { return nil }
                return Flashcard(id: $0.documentID, question: question, answer: answer, userID: userID)
            } ?? []
            DispatchQueue.main.async {
                self.showFlashcard()
            }
        }
    }
    
    func showFlashcard() {
        guard !flashcards.isEmpty else {
            cardLabel.text = "Kart yok"
            return
        }
        showingQuestion = true
        let flashcard = flashcards[currentIndex]
        cardLabel.text = flashcard.question
    }
    
    @objc func flipCard() {
        guard !flashcards.isEmpty else { return }
           let flashcard = flashcards[currentIndex]
           let toText = showingQuestion ? flashcard.answer : flashcard.question

           UIView.transition(with: cardLabel, duration: 0.5, options: .transitionFlipFromRight, animations: {
               self.cardLabel.text = toText
           }, completion: nil)

           showingQuestion.toggle()
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
        alert.addAction(UIAlertAction(title: "Ekle", style: .default, handler: { _ in
            guard let question = alert.textFields?[0].text, !question.isEmpty,
                  let answer = alert.textFields?[1].text, !answer.isEmpty else { return }
            self.addFlashcard(question: question, answer: answer)
        }))
        present(alert, animated: true)
    }
    
    func addFlashcard(question: String, answer: String) {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "question": question,
            "answer": answer,
            "userID": userID
        ]
        db.collection("Flashcards").addDocument(data: data) { error in
            if let error = error {
                print("Ekleme hatası: \(error)")
            } else {
                self.fetchFlashcards()
            }
        }
    }
}
