//
//  StudentAddLessonViewController.swift
//  Learnix
//
//  Created by Miray Erten on 17.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UniformTypeIdentifiers
import SafariServices // pdf seçip görüntülemek için, iosun kendi özelliği, dosyayı uygulama içi açmak için

class StudentAddLessonViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lessonNameLabel: UILabel!
    @IBOutlet weak var lessonNameTextField: UITextField!
    @IBOutlet weak var teacherNameLabel: UILabel!
    @IBOutlet weak var teacherNameTextField: UITextField!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var pdfStatusLabel: UILabel!
    
    var selectedPdfURL: URL?
    var ders: UserLessons?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pdfStatusLabel.isHidden = true
        setupEditModeIfNeeded()
    }
    
    func setupEditModeIfNeeded() {
        guard let ders = ders else {
            titleLabel.text = "Yeni Ders Ekle"
            return
        }
        
        lessonNameTextField.text = ders.lessonName
        teacherNameTextField.text = ders.teacherName
        titleLabel.text = "Dersi Düzenle"
        
        if let existingPdfUrl = ders.pdfURL, URL(string: existingPdfUrl) != nil {
            pdfStatusLabel.isHidden = false
            pdfStatusLabel.text = "PDF zaten eklenmiş 📎"
        }
    }
    
    
    @IBAction func uploadPdfTapped(_ sender: UIButton) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    
    
    @IBAction func saveLessonTapped(_ sender: UIButton) {
        guard let lessonName = lessonNameTextField.text, !lessonName.isEmpty,
              let teacherName = teacherNameTextField.text, !teacherName.isEmpty else {
            showAlert(title: "Eksik bilgi", message: "Lütfen tüm alanları doldurunuz.")
            return
        }
        
        if let pdfUrl = selectedPdfURL {
            uploadPdfToFirebase(fileURL: pdfUrl, lessonName: lessonName, teacherName: teacherName)
        } else if let ders = ders {
            updateLessonInFirestore(pdfURL: ders.pdfURL, lessonName: lessonName, teacherName: teacherName)
        } else {
            saveLessonToFirestore(pdfURL: nil, lessonName: lessonName, teacherName: teacherName)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedUrl = urls.first,
              selectedUrl.startAccessingSecurityScopedResource() else {
            print("Dosyaya erişim sağlanamadı.")
            return
        }
        
        defer { selectedUrl.stopAccessingSecurityScopedResource() }
        
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFileURL = tmpDir.appendingPathComponent(selectedUrl.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: tmpFileURL.path) {
                try FileManager.default.removeItem(at: tmpFileURL)
            }
            try FileManager.default.copyItem(at: selectedUrl, to: tmpFileURL)
            selectedPdfURL = tmpFileURL
            pdfStatusLabel.isHidden = false
            pdfStatusLabel.text = "✅ PDF başarıyla yüklendi: \(selectedUrl.lastPathComponent)"
        } catch {
            print("PDF kopyalanamadı: \(error.localizedDescription)")
        }
    }

    func uploadPdfToFirebase(fileURL: URL, lessonName: String, teacherName: String) {
        let storageRef = Storage.storage().reference()
        let fileName = UUID().uuidString + ".pdf"
        let pdfRef = storageRef.child("lesson_notes/\(fileName)")
        
        pdfRef.putFile(from: fileURL, metadata: nil) { _, error in
            if let error = error {
                self.showAlert(title: "Yükleme Hatası", message: error.localizedDescription)
                return
            }
            
            pdfRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    self.showAlert(title: "Hata", message: "PDF indirilebilir bağlantısı alınamadı.")
                    return
                }
                
                if self.ders != nil {
                    self.updateLessonInFirestore(pdfURL: downloadURL.absoluteString, lessonName: lessonName, teacherName: teacherName)
                } else {
                    self.saveLessonToFirestore(pdfURL: downloadURL.absoluteString, lessonName: lessonName, teacherName: teacherName)
                }
            }
        }
    }
    
    func saveLessonToFirestore(pdfURL: String?, lessonName: String, teacherName: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Hata", message: "Kullanıcı doğrulanamadı.")
            return
        }
        
        let newLessonData: [String: Any] = [
            "lessonName": lessonName,
            "teacherName": teacherName,
            "pdfURL": pdfURL as Any
        ]
        
        Firestore.firestore().collection("Users").document(uid).collection("Lessons").addDocument(data: newLessonData) { error in
            if let error = error {
                self.showAlert(title: "Hata", message: "Ders kaydedilemedi: \(error.localizedDescription)")
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func updateLessonInFirestore(pdfURL: String?, lessonName: String, teacherName: String) {
        guard let ders = ders,
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Hata", message: "Güncelleme için kullanıcı ya da ders bulunamadı.")
            return
        }
        
        let updatedData: [String: Any] = [
            "lessonName": lessonName,
            "teacherName": teacherName,
            "pdfURL": pdfURL as Any
        ]
        
        Firestore.firestore().collection("Users").document(uid).collection("Lessons").document(ders.id).updateData(updatedData) { error in
            if let error = error {
                self.showAlert(title: "Hata", message: "Güncelleme başarısız: \(error.localizedDescription)")
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
