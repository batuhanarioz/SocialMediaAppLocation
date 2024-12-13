//
//  EditFirstNameViewController.swift
//  KonumUyg
//
//  Created by reel on 14.11.2024.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditFirstNameViewController: UIViewController {
    
    private let firstNameTextField = UITextField()
    private let saveButton = UIButton(type: .system)
    private var currentUser: FirebaseAuth.User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Ad Düzenle"
        
        currentUser = FirebaseAuth.Auth.auth().currentUser
        setupUI()
    }
    
    private func setupUI() {
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.placeholder = "Yeni Ad"
        firstNameTextField.borderStyle = .roundedRect
        firstNameTextField.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(firstNameTextField)
        
        saveButton.setTitle("Kaydet", for: .normal)
        saveButton.addTarget(self, action: #selector(saveFirstName), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            firstNameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firstNameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            firstNameTextField.widthAnchor.constraint(equalToConstant: 300),
            
            saveButton.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func saveFirstName() {
        guard let newFirstName = firstNameTextField.text, !newFirstName.isEmpty else {
                return
            }
            
            let db = Firestore.firestore()
            guard let uid = currentUser?.uid else { return }
            
            db.collection("users").document(uid).updateData([
                "firstName": newFirstName
            ]) { error in
                if let error = error {
                    print("Error updating first name: \(error.localizedDescription)")
                } else {
                    print("First name updated successfully!")
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
                    let firstName = data["firstName"] as? String ?? "Ad yok"
                    self.firstNameTextField.text = firstName 
                }
            }
        }
    
    private func updateFirstNameInFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // Firebase'deki kullanıcı adı bilgisini güncelliyoruz
        db.collection("users").document(userID).updateData([
            "firstName": firstNameTextField.text ?? ""
        ]) { error in
            if let error = error {
                print("Error updating first name: \(error.localizedDescription)")
            } else {
                // Başarıyla güncellendikten sonra, profil sayfasındaki verilerin güncellenmesi için:
                self.fetchUserData()  // Profil verilerini yeniden yükle
                self.navigationController?.popViewController(animated: true)  // Profil sayfasına dön
            }
        }
    }


}
