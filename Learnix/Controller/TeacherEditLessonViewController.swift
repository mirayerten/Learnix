//
//  TeacherEditLessonViewController.swift
//  Learnix
//
//  Created by Miray Erten on 19.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UniformTypeIdentifiers

class TeacherEditLessonViewController: UIViewController, UIDocumentPickerDelegate {
    
    let db = Firestore.firestore()
    var lesson: Lesson? // Düzenlenecek ders
    
    @IBOutlet weak var lessonNameTextField: UITextField!
    @IBOutlet weak var teacherNameTextField: UITextField!
    @IBOutlet weak var selectPDFButton: UIButton!
    @IBOutlet weak var pdfStatusLabel: UILabel!
    
    var selectedPDFURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateFields()
    }
    
    private func populateFields() {
        lessonNameTextField.text = lesson?.lessonName
        teacherNameTextField.text = lesson?.teacherName
        
        if let pdfUrlString = lesson?.pdfURL, !pdfUrlString.isEmpty {
            pdfStatusLabel.text = "PDF mevcut"
        } else {
            pdfStatusLabel.text = "PDF eklenmemiş"
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedUrl = urls.first else { return }
        
        guard selectedUrl.startAccessingSecurityScopedResource() else {
            showAlert(title: "Hata", message: "Dosyaya erişim sağlanamadı.")
            return
        }
        defer { selectedUrl.stopAccessingSecurityScopedResource() }
        
        let fileManager = FileManager.default
        let tmpDir = fileManager.temporaryDirectory
        let tmpFileURL = tmpDir.appendingPathComponent(selectedUrl.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: tmpFileURL.path) {
                try fileManager.removeItem(at: tmpFileURL)
            }
            try fileManager.copyItem(at: selectedUrl, to: tmpFileURL)
            selectedPDFURL = tmpFileURL
            pdfStatusLabel.text = "PDF seçildi: \(selectedUrl.lastPathComponent)"
        } catch {
            showAlert(title: "Dosya Hatası", message: "PDF kopyalanamadı: \(error.localizedDescription)")
        }
    }
    
    private func uploadPdfToFirebase(fileURL: URL, lessonName: String, teacherName: String) {
        let storageRef = Storage.storage().reference().child("lesson_notes/\(UUID().uuidString).pdf")
        
        storageRef.putFile(from: fileURL, metadata: nil) { [weak self] metadata, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Yükleme Hatası", message: error.localizedDescription)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let downloadURL = url {
                    self.saveLessonToFirestore(pdfURL: downloadURL.absoluteString, lessonName: lessonName, teacherName: teacherName)
                } else if let error = error {
                    self.showAlert(title: "Hata", message: "PDF linki alınamadı: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveLessonToFirestore(pdfURL: String, lessonName: String, teacherName: String) {
        guard let email = Auth.auth().currentUser?.email else {
            showAlert(title: "Hata", message: "Kullanıcı doğrulanamadı.")
            return
        }
        
        let data: [String: Any] = [
            "lessonName": lessonName,
            "teacherName": teacherName,
            "teacherEmail": email,
            "pdfURL": pdfURL
        ]
        
        if let lessonId = lesson?.id {
            // Güncelleme işlemi
            db.collection("TeacherLessons").document(lessonId).setData(data) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Güncelleme Hatası", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "Başarılı", message: "Ders başarıyla güncellendi.") {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        } else {
            // Yeni kayıt işlemi
            db.collection("TeacherLessons").addDocument(data: data) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Kaydetme Hatası", message: error.localizedDescription)
                } else {
                    self?.showAlert(title: "Başarılı", message: "Ders başarıyla eklendi.") {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func selectPDFTapped(_ sender: UIButton) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let lessonName = lessonNameTextField.text, !lessonName.isEmpty,
              let teacherName = teacherNameTextField.text, !teacherName.isEmpty else {
            showAlert(title: "Eksik bilgi", message: "Lütfen tüm alanları doldurunuz.")
            return
        }
        
        // Eğer düzenleme modundaysak ve yeni PDF seçilmemişse, var olan URL'yi kullan
        if let existingLesson = lesson, selectedPDFURL == nil {
            saveLessonToFirestore(
                pdfURL: existingLesson.pdfURL ?? "",
                lessonName: lessonName,
                teacherName: teacherName
            )
            return
        }
        
        // Yeni kayıt ya da yeni PDF seçilmişse upload et
        guard let pdfUrl = selectedPDFURL else {
            showAlert(title: "Eksik bilgi", message: "Lütfen PDF dosyası seçiniz.")
            return
        }
        
        uploadPdfToFirebase(fileURL: pdfUrl, lessonName: lessonName, teacherName: teacherName)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
