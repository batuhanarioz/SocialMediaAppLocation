//
//  EditUsernameViewController.swift
//  KonumUyg
//
//  Created by reel on 14.11.2024.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditUsernameViewController: UIViewController {
    
    private let usernameTextField = UITextField()
    private let saveButton = UIButton(type: .system)
    private var currentUser: FirebaseAuth.User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Kullanıcı Adı Düzenle"
        
        currentUser = FirebaseAuth.Auth.auth().currentUser
        setupUI()
        fetchUserData()  // Kullanıcı verilerini çek
    }
    
    private func setupUI() {
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.placeholder = "Yeni Kullanıcı Adı"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(usernameTextField)
        
        saveButton.setTitle("Kaydet", for: .normal)
        saveButton.addTarget(self, action: #selector(saveUsername), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            usernameTextField.widthAnchor.constraint(equalToConstant: 300),
            
            saveButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func saveUsername() {
            guard let newUsername = usernameTextField.text, !newUsername.isEmpty else {
                showAlert(message: "Lütfen geçerli bir kullanıcı adı girin.")
                return
            }

            // Kullanıcı adı eşsizlik kontrolünü yapalım
            checkIfUsernameExists(username: newUsername) { exists in
                if exists {
                    // Eğer kullanıcı adı zaten varsa, kullanıcıya hata mesajı gösterelim
                    self.showAlert(message: "Bu kullanıcı adı zaten alınmış.")
                } else {
                    // Kullanıcı adı eşsizse, Firestore'da güncelleme yapalım
                    self.updateUsernameInFirestore(newUsername: newUsername)
                }
            }
        }

    private func checkIfUsernameExists(username: String, completion: @escaping (Bool) -> Void) {
            let db = Firestore.firestore()
            db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
                if let error = error {
                    print("Hata oluştu: \(error.localizedDescription)")
                    completion(false)  // Hata durumunda eşsizlik kontrolü başarılı sayılır
                } else if let snapshot = snapshot, !snapshot.isEmpty {
                    // Kullanıcı adı zaten var
                    completion(true)
                } else {
                    // Kullanıcı adı eşsiz
                    completion(false)
                }
            }
        }
        
        private func updateUsernameInFirestore(newUsername: String) {
            guard let userID = currentUser?.uid else { return }
            let db = Firestore.firestore()

            // Firebase'deki kullanıcı adı bilgisini güncelliyoruz
            db.collection("users").document(userID).updateData([
                "username": newUsername
            ]) { error in
                if let error = error {
                    print("Error updating username: \(error.localizedDescription)")
                } else {
                    print("Username updated successfully!")
                    self.fetchUserData()  // Profil verilerini yeniden yükle
                    self.navigationController?.popViewController(animated: true)  // Profil sayfasına dön
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
                    let username = data["username"] as? String ?? "Kullanıcı adı yok"
                    self.usernameTextField.text = username // Mevcut kullanıcı adını textfield'a yükle
                }
            }
        }
        
        private func showAlert(message: String) {
            let alert = UIAlertController(title: "Bilgi", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }
}
