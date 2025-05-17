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
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
            profileImageView.clipsToBounds = true
        }
        
        @IBAction func selectPhotoTapped(_ sender: UIButton) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            present(picker, animated: true)
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
                uploadProfileImage(image, forUID: uid) { url in
                    self.saveUserInfo(uid: uid, name: name, school: school, grade: grade, imageUrl: url)
                }
            } else {
                self.saveUserInfo(uid: uid, name: name, school: school, grade: grade, imageUrl: nil)
            }
        }
        
        func uploadProfileImage(_ image: UIImage, forUID uid: String, completion: @escaping (String?) -> Void) {
            let imageData = image.jpegData(compressionQuality: 0.8)!
            let storageRef = storage.reference().child("profileImages/\(uid).jpg")
            
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    self.showAlert(title: "Resim Hatası", message: error.localizedDescription)
                    completion(nil)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let downloadURL = url?.absoluteString {
                        completion(downloadURL)
                    } else {
                        completion(nil)
                    }
                }
            }
        }

        func saveUserInfo(uid: String, name: String, school: String, grade: String, imageUrl: String?) {
            var userData: [String: Any] = [
                "name": name,
                "school": school,
                "grade": grade
            ]
            
            if let imageUrl = imageUrl {
                userData["profileImageUrl"] = imageUrl
            }
            
            db.collection("Users").document(uid).updateData(userData) { error in
                if let error = error {
                    self.showAlert(title: "Kayıt Hatası", message: error.localizedDescription)
                } else {
                    self.yonlendirAnaSayfaya()
                }
            }
        }
        
        func yonlendirAnaSayfaya() {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            db.collection("Users").document(uid).getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let role = data["role"] as? String {
                    
                    if role == "student" {
                        self.performSegue(withIdentifier: "profileToStudentHome", sender: self)
                    } else {
                        self.performSegue(withIdentifier: "profileToTeacherHome", sender: self)
                    }
                }
            }
        }

        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let ok = UIAlertAction(title: "Tamam", style: .default)
            alert.addAction(ok)
            present(alert, animated: true)
        }
    }
