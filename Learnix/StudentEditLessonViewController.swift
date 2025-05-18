//
//  StudentEditLessonViewController.swift
//  Learnix
//
//  Created by Miray Erten on 18.05.2025.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import MobileCoreServices

class StudentEditLessonViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var duzenleLabel: UILabel!
    @IBOutlet weak var lessonNameLabel: UILabel!
    @IBOutlet weak var lessonNameTextField: UITextField!
    @IBOutlet weak var teacherNameLabel: UILabel!
    @IBOutlet weak var teacherNameTextField: UITextField!
    @IBOutlet weak var pdfLabel: UILabel!
    @IBOutlet weak var pdfSelectButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var ders: Ders?
    var editingDers: Ders?
    var selectedPdfLocalUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadDersData()
    }
    
    func loadDersData() {
        guard let ders = ders else { return }
        lessonNameTextField.text = ders.lessonName
        teacherNameTextField.text = ders.teacherName
    }
    
    @IBAction func pdfSelectButtonTapped(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedUrl = urls.first else { return }
        selectedPdfLocalUrl = pickedUrl
        showAutoDismissAlert(title: "Başarılı", message: "Yeni PDF eklendi")
    }


    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let ders = ders,
              let lessonName = lessonNameTextField.text, !lessonName.isEmpty,
              let teacherName = teacherNameTextField.text, !teacherName.isEmpty
        else {
            showAlert(title: "Eksik Bilgi", message: "Lütfen ders adı ve öğretmen adını doldurun.")
            return
        }
        if let localPdfUrl = selectedPdfLocalUrl {
            uploadPdfToStorage(localFileUrl: localPdfUrl) { [weak self] result in switch result {
                case .success(let downloadUrl): self?.updateFirestoreData(lessonName: lessonName, teacherName: teacherName, pdfUrl: downloadUrl.absoluteString)
                case .failure(let error): DispatchQueue.main.async {
                    self?.showAlert(title: "Hata", message: "PDF yükleme başarısız: \(error.localizedDescription)")
                }
            }
            }
        } else {
            updateFirestoreData(lessonName: lessonName, teacherName: teacherName, pdfUrl: ders.pdfURL)
        }
    }
            
    private func uploadPdfToStorage(localFileUrl: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let pdfRef = storageRef.child("dersler_pdfs/\(UUID().uuidString).pdf")
            
        pdfRef.putFile(from: localFileUrl, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            pdfRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadUrl = url else {
                    completion(.failure(NSError(domain: "URLNotFound", code: -1, userInfo: nil)))
                    return
                }
                completion(.success(downloadUrl))
            }
        }
    }

    private func updateFirestoreData(lessonName: String, teacherName: String, pdfUrl: String?) {
        guard let ders = ders else { return }
            
        let db = Firestore.firestore()
        db.collection("Dersler").document(ders.id).updateData([
            "lessonName": lessonName,
            "teacherName": teacherName,
            "pdfUrl": pdfUrl as Any
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Hata", message: "Güncelleme başarısız: \(error.localizedDescription)")
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
        
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
        
    private func showAutoDismissAlert(title: String, message: String, duration: Double = 1.5) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alert.dismiss(animated: true)
        }
    }
}
