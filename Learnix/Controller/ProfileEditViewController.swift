//
//  ProfileEditViewController.swift
//  Learnix
//
//  Created by Miray Erten on 17.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class ProfileEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var schoolTextField: UITextField!
    @IBOutlet weak var gradeTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        fetchUserRole()
    }
    
    @IBAction func selectPhotoTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func fetchUserRole() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Rol alınırken hata: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), let role = data["role"] as? String {
                if role == "teacher" {
                    self.gradeTextField.isHidden = true
                }
            }
        }
    }
    
    // Kullanıcı fotoğraf seçtiğinde çalışır
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            profileImageView.image = image
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty,
              let school = schoolTextField.text, !school.isEmpty,
              let grade = gradeTextField.text, !grade.isEmpty,
              let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "Eksik Bilgi", message: "Tüm alanları doldurun.")
            return
        }
        
        // Önce resim varsa yükle, yoksa direkt bilgileri Firestore’a yaz
        if let image = selectedImage {
            uploadImage(image, uid: uid) { imageUrl in
                self.saveUserData(uid: uid, name: name, school: school, grade: grade, imageUrl: imageUrl)
            }
        } else {
            saveUserData(uid: uid, name: name, school: school, grade: grade, imageUrl: nil)
        }
    }
    
    func uploadImage(_ image: UIImage, uid: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        
        let imageRef = storage.reference().child("profileImages/\(uid).jpg")
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                self.showAlert(title: "Resim Hatası", message: error.localizedDescription)
                completion(nil)
                return
            }
            imageRef.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
    
    func saveUserData(uid: String, name: String, school: String, grade: String, imageUrl: String?) {
        var data: [String: Any] = [
            "name": name,
            "school": school,
            "grade": grade
        ]
        
        if let imageUrl = imageUrl {
            data["photoURL"] = imageUrl
        }
        
        db.collection("Users").document(uid).updateData(data) { error in
            if let error = error {
                self.showAlert(title: "Kayıt Hatası", message: error.localizedDescription)
            } else {
                self.navigateToHome()
            }
        }
    }
    
    func navigateToHome() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("Users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let role = data["role"] as? String {
                let segueId = (role == "student") ? "profileToStudentHome" : "profileToTeacherHome"
                self.performSegue(withIdentifier: segueId, sender: self)
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
