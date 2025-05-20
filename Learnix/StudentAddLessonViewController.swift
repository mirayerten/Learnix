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
    @IBOutlet weak var pdfImageView: UIImageView!
    
    var selectedPdfURL: URL?
    var ders: Ders?

    override func viewDidLoad() {
        super.viewDidLoad()
        pdfImageView.isHidden = true
        
    }

    @IBAction func uploadPdfTapped(_ sender: UIButton) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedUrl = urls.first else { return }
        guard selectedUrl.startAccessingSecurityScopedResource() else {
                print("Dosyaya erişim sağlanamadı.")
                return
            }
        defer { selectedUrl.stopAccessingSecurityScopedResource() }

            // Geçici dizine kopyala
            let fileManager = FileManager.default
            let tmpDir = FileManager.default.temporaryDirectory
            let tmpFileURL = tmpDir.appendingPathComponent(selectedUrl.lastPathComponent)

            do {
                if fileManager.fileExists(atPath: tmpFileURL.path) {
                    try fileManager.removeItem(at: tmpFileURL) // Önceki varsa sil
                }
                try fileManager.copyItem(at: selectedUrl, to: tmpFileURL)
                selectedPdfURL = tmpFileURL
                print("PDF kopyalandı: \(tmpFileURL.lastPathComponent)")
            } catch {
                print("PDF kopyalanamadı: \(error.localizedDescription)")
            }
        self.pdfImageView.isHidden = false
    }

    @IBAction func saveLessonTapped(_ sender: UIButton) {
        guard let lessonName = lessonNameTextField.text, !lessonName.isEmpty,
                      let teacherName = teacherNameTextField.text, !teacherName.isEmpty else {
                    showAlert(title: "Eksik bilgi", message: "Lütfen tüm alanları doldurunuz.")
                    return
                }

                if let pdfUrl = selectedPdfURL {
                    uploadPdfToFirebase(fileURL: pdfUrl, lessonName: lessonName, teacherName: teacherName)
                } else {
                    saveLessonToFirestore(pdfURL: nil, lessonName: lessonName, teacherName: teacherName)
                }
            }

            func uploadPdfToFirebase(fileURL: URL, lessonName: String, teacherName: String) {
                let storage = Storage.storage()
                let storageRef = storage.reference()
                let fileName = UUID().uuidString + ".pdf"
                let pdfRef = storageRef.child("lesson_notes/\(fileName)")

                pdfRef.putFile(from: fileURL, metadata: nil) { metadata, error in
                    if let error = error {
                        self.showAlert(title: "Yükleme Hatası", message: error.localizedDescription)
                        return
                    }

                    pdfRef.downloadURL { url, error in
                        if let url = url {
                            self.saveLessonToFirestore(pdfURL: url.absoluteString, lessonName: lessonName, teacherName: teacherName)
                        }
                    }
                }
            }

    func saveLessonToFirestore(pdfURL: String?, lessonName: String, teacherName: String) {
        let db = Firestore.firestore()
            guard let uid = Auth.auth().currentUser?.uid else {
                showAlert(title: "Hata", message: "Kullanıcı doğrulanamadı.")
                return
            }

            let newLessonData: [String: Any] = [
                "lessonName": lessonName,
                "teacherName": teacherName,
                "pdfURL": pdfURL as Any
            ]

            db.collection("Users").document(uid).collection("Lessons").addDocument(data: newLessonData) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Hata", message: "Ders kaydedilemedi: \(error.localizedDescription)")
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
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
