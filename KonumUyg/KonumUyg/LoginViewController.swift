//
//  LoginViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    private let usernameTextField: UITextField = {
            let textField = UITextField()
            textField.placeholder = "Kullanıcı Adı"
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            return textField
        }()
        
        private let passwordTextField: UITextField = {
            let textField = UITextField()
            textField.placeholder = "Şifre"
            textField.borderStyle = .roundedRect
            textField.isSecureTextEntry = true
            textField.translatesAutoresizingMaskIntoConstraints = false
            return textField
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .white
            setupUI()
        }
        
        private func setupUI() {
            // Başlık Label
            let titleLabel = UILabel()
            titleLabel.text = "Giriş Yap"
            titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(titleLabel)
            
            // UI elemanlarını ekle
            view.addSubview(usernameTextField)
            view.addSubview(passwordTextField)
            
            // Giriş Butonu
            let loginButton = UIButton(type: .system)
            loginButton.setTitle("Giriş Yap", for: .normal)
            loginButton.backgroundColor = .systemBlue
            loginButton.tintColor = .white
            loginButton.layer.cornerRadius = 5
            loginButton.translatesAutoresizingMaskIntoConstraints = false
            loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
            view.addSubview(loginButton)
            
            // Kayıt Ol Butonu
            let registerButton = UIButton(type: .system)
            registerButton.setTitle("Kayıt Ol", for: .normal)
            registerButton.tintColor = .systemBlue
            registerButton.translatesAutoresizingMaskIntoConstraints = false
            registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
            view.addSubview(registerButton)
            
            // AutoLayout ile konumlandırma
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
                
                usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                usernameTextField.widthAnchor.constraint(equalToConstant: 250),
                
                passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 10),
                passwordTextField.widthAnchor.constraint(equalToConstant: 250),
                
                loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
                loginButton.widthAnchor.constraint(equalToConstant: 250),
                loginButton.heightAnchor.constraint(equalToConstant: 50),
                
                registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 10)
            ])
        }
    
    // getEmailFromUsername işlevini burada tanımlıyoruz
        private func getEmailFromUsername(username: String, completion: @escaping (String?) -> Void) {
            let db = Firestore.firestore()
            
            db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore hatası: \(error.localizedDescription)")
                    completion(nil)
                } else if let document = snapshot?.documents.first {
                    let email = document.data()["email"] as? String
                    completion(email)
                } else {
                    completion(nil)
                }
            }
        }
        
    @objc private func loginTapped() {
            guard let username = usernameTextField.text, !username.isEmpty,
                  let password = passwordTextField.text, !password.isEmpty else {
                print("Lütfen kullanıcı adı ve şifreyi girin.")
                return
            }
            
            // Kullanıcı adı ile ilişkili e-posta adresini al
            getEmailFromUsername(username: username) { [weak self] email in
                guard let self = self else { return }
                
                if let email = email {
                    // Firebase ile e-posta ve şifre üzerinden giriş işlemi
                    Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                        if let error = error {
                            print("Giriş başarısız: \(error.localizedDescription)")
                        } else {
                            print("Giriş başarılı!")
                            // Kullanıcı adını almak için Firebase'den kullanıcı verilerini al
                            if let currentUser = authResult?.user {
                                FirebaseHelper.fetchUsernameFromFirestore(uid: currentUser.uid) { username in
                                    guard let username = username else {
                                        print("Username alınamadı")
                                        return
                                    }
                                    
                                    // ProfileViewController'ı username parametresi ile başlat
                                    let profileVC = ProfileViewController(username: username)
                                    profileVC.modalPresentationStyle = .fullScreen
                                    self.present(profileVC, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else {
                    print("Kullanıcı adı ile ilişkili bir e-posta bulunamadı.")
                }
            }
        }
    
    @objc private func registerTapped() {
        let registerVC = RegisterViewController()
        registerVC.modalPresentationStyle = .fullScreen
        present(registerVC, animated: true, completion: nil)
    }

    
}
