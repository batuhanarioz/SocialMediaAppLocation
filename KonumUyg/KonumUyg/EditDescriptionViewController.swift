//
//  EditDescriptionViewController.swift
//  KonumUyg
//
//  Created by reel on 14.11.2024.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditDescriptionViewController: UIViewController {
    
    private let descriptionTextView = UITextView()
    private let saveButton = UIButton(type: .system)
    private var currentUser: FirebaseAuth.User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Açıklama Düzenle"
        
        currentUser = FirebaseAuth.Auth.auth().currentUser
        setupUI()
    }
    
    private func setupUI() {
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.font = UIFont.systemFont(ofSize: 16)
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor.gray.cgColor
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.text = "Yeni açıklamanızı buraya girin..."
        view.addSubview(descriptionTextView)
        
        saveButton.setTitle("Kaydet", for: .normal)
        saveButton.addTarget(self, action: #selector(saveDescription), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            descriptionTextView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            descriptionTextView.widthAnchor.constraint(equalToConstant: 300),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 150),
            
            saveButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func saveDescription() {
            guard let newDescription = descriptionTextView.text, !newDescription.isEmpty else {
                return
            }
            
            let db = Firestore.firestore()
            guard let uid = currentUser?.uid else { return }
            
            db.collection("users").document(uid).updateData([
                "description": newDescription
            ]) { error in
                if let error = error {
                    print("Error updating description: \(error.localizedDescription)")
                } else {
                    print("Description updated successfully!")
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
                    let description = data["description"] as? String ?? "Açıklama yok"
                    self.descriptionTextView.text = description // Mevcut açıklamayı textview'a yükle
                }
            }
        }
    
    private func updateDescriptionInFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID).updateData([
            "description": descriptionTextView.text ?? ""
        ]) { error in
            if let error = error {
                print("Error updating description: \(error.localizedDescription)")
            } else {
                self.fetchUserData()  // Profil verilerini yeniden yükle
                self.navigationController?.popViewController(animated: true)  // Profil sayfasına dön
            }
        }
    }

}
