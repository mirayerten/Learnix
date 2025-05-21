//
//  StudentUserSettingsViewController.swift
//  Learnix
//
//  Created by Miray Erten on 20.05.2025.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import PhotosUI

class StudentUserSettingsViewController: UIViewController, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    
    let db = Firestore.firestore()
    
    private func setupProfileImageView() {
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectProfileImage))
        imageView.addGestureRecognizer(tapGesture)
    }

    private func fetchUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("Users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Hata", message: "Kullanıcı bilgileri alınamadı: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let photoURL = data["photoURL"] as? String ?? ""
            
            DispatchQueue.main.async {
                self.nameTextField.text = name
                self.emailTextField.text = email
                
                if let url = URL(string: photoURL), !photoURL.isEmpty {
                    self.loadImage(from: url)
                } else {
                    self.imageView.image = UIImage(systemName: "person.circle.fill")
                }
            }
        }
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: data)
            }
        }.resume()
    }

    @objc private func selectProfileImage() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self = self, let selectedImage = image as? UIImage, error == nil else { return }
            DispatchQueue.main.async {
                self.imageView.image = selectedImage
                self.uploadProfileImage(selectedImage)
            }
        }
    }

    private func uploadProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.75),
              let uid = Auth.auth().currentUser?.uid else { return }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error {
                self?.showAlert(title: "Hata", message: "Resim yüklenemedi: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url, error == nil else { return }
                self?.updateUserProfileImageURL(downloadURL.absoluteString)
            }
        }
    }
    
    private func updateUserProfileImageURL(_ urlString: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("Users").document(uid).updateData(["photoURL": urlString]) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Hata", message: "Profil resmi güncellenemedi: \(error.localizedDescription)")
            } else {
                self?.showAlert(title: "Başarılı", message: "Profil resmi güncellendi.")
            }
        }
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        guard let newName = nameTextField.text, !newName.isEmpty else {
            showAlert(title: "Uyarı", message: "İsim boş bırakılamaz.")
            return
        }
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = newName
        changeRequest?.commitChanges { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Hata", message: "Profil güncellenemedi: \(error.localizedDescription)")
            } else {
                self?.showAlert(title: "Başarılı", message: "Profil güncellendi.") {
                    if let nav = self?.navigationController {
                        nav.popViewController(animated: true)
                    } else {
                        self?.dismiss(animated: true)
                    }
                }
            }
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
