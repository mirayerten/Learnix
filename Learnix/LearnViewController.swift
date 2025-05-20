//
//  LearnViewController.swift
//  Learnix
//
//  Created by Miray Erten on 19.05.2025.
//

import UIKit
import Firebase
import FirebaseFirestore
import SafariServices

struct Flashcard {
    let id: String
    let question: String
    let answer: String
    let userID: String
}

struct Quiz {
    let question: String
    let options: [String]
    let correctIndex: Int
}

enum QuizError: Error {
    case invalidResponse
}

struct TLesson {
    let id: String
    let name: String
    let teacherName: String
    let pdfURL: String?
}

class LearnViewController: UIViewController {
    

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardLabel: UILabel!
    

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var flashcards: [Flashcard] = []
    var currentIndex: Int = 0
    var showingQuestion = true
    let userID = "testUser123" // Giriş yapan kullanıcıya göre değiştir
    
    var lessons: [TLesson] = []
    var filteredLessons: [TLesson] = []
    
    var correctAnswer: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchFlashcards()
        
        // TableView ve SearchBar delegate & datasource ayarla
            tableView.delegate = self
            tableView.dataSource = self
            searchBar.delegate = self
            
            // Başlangıçta flashcard görünür, liste ve arama gizli
            cardView.isHidden = false
            tableView.isHidden = true
            searchBar.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(flipCard))
        cardLabel.isUserInteractionEnabled = true
        cardLabel.addGestureRecognizer(tapGesture)
        
        // Segment değişimini dinle
            segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
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
    
    func deleteCurrentFlashcard() {
        guard !flashcards.isEmpty else { return }
        let db = Firestore.firestore()
        let flashcard = flashcards[currentIndex]
        
        db.collection("Flashcards").document(flashcard.id).delete { error in
            if let error = error {
                print("Silme hatası: \(error)")
            } else {
                print("Kart silindi.")
                self.flashcards.remove(at: self.currentIndex)
                
                // Yeni index belirleme
                if self.currentIndex >= self.flashcards.count {
                    self.currentIndex = max(self.flashcards.count - 1, 0)
                }
                
                DispatchQueue.main.async {
                    self.showFlashcard()
                }
            }
        }
    }
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Flashcard görünür, ders listesi ve arama gizli
            cardView.isHidden = false
            tableView.isHidden = true
            searchBar.isHidden = true
        } else {
            // Ders listesi görünür, flashcard gizli, arama görünür
            cardView.isHidden = true
            tableView.isHidden = false
            searchBar.isHidden = false
            fetchLessons(teacherName: "") // İlk açılışta boş arama ile tüm dersleri çek
        }
    }
    
    func fetchLessons(teacherName: String) {
        let db = Firestore.firestore()
        var query: Query = db.collection("TeacherLessons")
        
        if !teacherName.isEmpty {
            // Öğretmen adına göre filtreleme, case insensitive arama için Firestore kısıtlıdır ama basit prefix araması yapılabilir:
            query = query.whereField("teacherName", isEqualTo: teacherName)
        }
        
        query.getDocuments { snapshot, error in
            guard error == nil, let documents = snapshot?.documents else {
                print("Ders çekme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                return
            }
            
            self.lessons = documents.compactMap {
                let data = $0.data()
                let name = data["lessonName"] as? String ?? ""
                let teacher = data["teacherName"] as? String ?? ""
                let pdfURL = data["pdfURL"] as? String
                return TLesson(id: $0.documentID, name: name, teacherName: teacher, pdfURL: pdfURL)
            }
            
            // Başlangıçta filtrelenmiş liste tüm dersler
            self.filteredLessons = self.lessons
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
 /*   @IBAction func deleteTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Sil", message: "Bu kartı silmek istediğine emin misin?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
            alert.addAction(UIAlertAction(title: "Sil", style: .destructive, handler: { _ in
                self.deleteCurrentFlashcard()
            }))
            present(alert, animated: true)
    }
    
   
    
    @IBAction func generateQuizTapped(_ sender: UIButton) {
        guard let topic = topicTextField.text, !topic.isEmpty else { return }
               generateQuiz(for: topic) { question, options, answer in
                   DispatchQueue.main.async {
                       self.quizLabel.text = question
                       self.correctAnswer = answer
                       for i in 0..<self.optionButtons.count {
                           self.optionButtons[i].setTitle(options[i], for: .normal)
                           self.optionButtons[i].backgroundColor = .systemBlue
                       }
                       self.resultLabel.text = ""
                   }
               }
    }
    
    @IBAction func optionSelected(_ sender: UIButton) {
        guard let selected = sender.title(for: .normal) else { return }
        
        if selected == correctAnswer {
            sender.backgroundColor = .systemGreen
            resultLabel.text = "✅ Doğru!"
        } else {
            sender.backgroundColor = .systemRed
            resultLabel.text = "❌ Yanlış!"
            if let correct = optionButtons.first(where: { $0.title(for: .normal) == correctAnswer }) {
                correct.backgroundColor = .systemGreen
            }
        }
    }
    func generateQuiz(for topic: String, completion: @escaping (String, [String], String) -> Void) {
            let apiKey = "YOUR_OPENAI_API_KEY"
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!

            let prompt = """
            \(topic) hakkında bir tane çoktan seçmeli quiz sorusu üret. JSON formatında sadece şunu döndür:
            {
                "question": "Osmanlı Devleti hangi tarihte kurulmuştur?",
                  "options": ["1299", "1453", "1071", "1923"],
                  "correctIndex": 0
            }
            """

            let body: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    ["role": "system", "content": "Sen bir quiz üreticisisin."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.7
            ]

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    print("API Hatası: \(error?.localizedDescription ?? "bilinmiyor")")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String,
                       let jsonData = content.data(using: .utf8),
                       let quiz = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let question = quiz["question"] as? String,
                       let options = quiz["options"] as? [String],
                       let correctIndex = quiz["correctIndex"] as? Int {
                        
                        let quizData = Quiz(question: question, options: options, correctIndex: correctIndex)
                        completion(.success(quizData))
                    } else {
                        completion(.failure(QuizError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        }*/
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "LessonCell", for: indexPath)
            let lesson = filteredLessons[indexPath.row]
            cell.textLabel?.text = lesson.name
            cell.detailTextLabel?.text = lesson.teacherName
            return cell
    }
    
    // İstersen seçilen dersi işle (pdf gösterme gibi)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
            let lesson = filteredLessons[indexPath.row]
            print("Seçilen ders: \(lesson.name)")
            
            if let pdfString = lesson.pdfURL, let url = URL(string: pdfString) {
                let safariVC = SFSafariViewController(url: url)
                present(safariVC, animated: true)
            } else {
                // PDF yoksa veya geçersiz URL
                let alert = UIAlertController(title: "PDF yok", message: "Bu ders için PDF bulunmamaktadır.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                present(alert, animated: true)
            }
        }
}
