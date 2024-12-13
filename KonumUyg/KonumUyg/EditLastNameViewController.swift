//
//  EditLastNameViewController.swift
//  KonumUyg
//
//  Created by reel on 14.11.2024.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditLastNameViewController: UIViewController {
    
    private let lastNameTextField = UITextField()
    private let saveButton = UIButton(type: .system)
    private var currentUser: FirebaseAuth.User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Soyad Düzenle"
        
        currentUser = FirebaseAuth.Auth.auth().currentUser
        setupUI()
    }
    
    private func setupUI() {
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.placeholder = "Yeni Soyad"
        lastNameTextField.borderStyle = .roundedRect
        lastNameTextField.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(lastNameTextField)
        
        saveButton.setTitle("Kaydet", for: .normal)
        saveButton.addTarget(self, action: #selector(saveLastName), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            lastNameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lastNameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            lastNameTextField.widthAnchor.constraint(equalToConstant: 300),
            
            saveButton.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func saveLastName() {
            guard let newLastName = lastNameTextField.text, !newLastName.isEmpty else {
                return
            }
            
            let db = Firestore.firestore()
            guard let uid = currentUser?.uid else { return }
            
            db.collection("users").document(uid).updateData([
                "lastName": newLastName
            ]) { error in
                if let error = error {
                    print("Error updating last name: \(error.localizedDescription)")
                } else {
                    print("Last name updated successfully!")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }

        private func fetchUserData() {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(userID).getDocument { snapshot, error in
                if let error = error {
                    print("Veri çekilemedi: \(error.localizedDescription)")
                    return
                }
                if let data = snapshot?.data() {
                    let lastName = data["lastName"] as? String ?? "Soyad yok"
                    self.lastNameTextField.text = lastName // Mevcut soyadı textfield'a yükle
                }
            }
        }
    
    private func updateLastNameInFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID).updateData([
            "lastName": lastNameTextField.text ?? ""
        ]) { error in
            if let error = error {
                print("Error updating last name: \(error.localizedDescription)")
            } else {
                self.fetchUserData()  // Profil verilerini yeniden yükle
                self.navigationController?.popViewController(animated: true)  // Profil sayfasına dön
            }
        }
    }

}
