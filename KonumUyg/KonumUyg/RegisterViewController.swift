//
//  RegisterViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

//
//  RegisterViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {
    
    // UI Elemanlarını tanımla
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "E-posta"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
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
    
    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifreyi Onayla"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let firstNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Ad"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let lastNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Soyad"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Kullanıcı Adı"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none // Otomatik büyük harf kullanımı kapatılıyor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        // Kullanıcı adını her değiştiğinde küçük harfe dönüştür
        usernameTextField.addTarget(self, action: #selector(usernameTextChanged), for: .editingChanged)
    }
    
    @objc private func usernameTextChanged() {
        // Kullanıcı adı alanını küçük harfe dönüştür
        usernameTextField.text = usernameTextField.text?.lowercased()
    }
    
    private func setupUI() {
        // Başlık Label
        let titleLabel = UILabel()
        titleLabel.text = "Kayıt Ol"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // UI Elemanlarını view'a ekle
        view.addSubview(emailTextField)
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(firstNameTextField)
        view.addSubview(lastNameTextField)
        
        // Kayıt Ol Butonu
        let registerButton = UIButton(type: .system)
        registerButton.setTitle("Kayıt Ol", for: .normal)
        registerButton.backgroundColor = .systemGreen
        registerButton.tintColor = .white
        registerButton.layer.cornerRadius = 5
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        view.addSubview(registerButton)
        
        // Geri Butonu
        let backButton = UIButton(type: .system)
        backButton.setTitle("Geri", for: .normal)
        backButton.tintColor = .systemBlue
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        // AutoLayout ile Konumlandırma
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),

            emailTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            emailTextField.widthAnchor.constraint(equalToConstant: 250),

            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 10),
            usernameTextField.widthAnchor.constraint(equalToConstant: 250),

            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 10),
            passwordTextField.widthAnchor.constraint(equalToConstant: 250),
            
            confirmPasswordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 10),
            confirmPasswordTextField.widthAnchor.constraint(equalToConstant: 250),
            
            firstNameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firstNameTextField.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 10),
            firstNameTextField.widthAnchor.constraint(equalToConstant: 250),

            lastNameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 10),
            lastNameTextField.widthAnchor.constraint(equalToConstant: 250),

            registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            registerButton.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 20),
            registerButton.widthAnchor.constraint(equalToConstant: 250),
            registerButton.heightAnchor.constraint(equalToConstant: 50),

            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 40)
        ])
    }

    @objc private func registerTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty,
              let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "Hata", message: "Lütfen tüm alanları doldurun.")
            return
        }

        // Şifrelerin eşleşip eşleşmediğini kontrol et
        if password != confirmPassword {
            showAlert(title: "Hata", message: "Şifreler uyuşmuyor!")
            return
        }

        // Kullanıcı adının benzersiz olup olmadığını kontrol et
        isUsernameUnique(username.lowercased()) { [weak self] isUnique in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if isUnique {
                    // Benzersiz ise, Firebase ile kayıt işlemi
                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                        if let error = error {
                            self.showAlert(title: "Kayıt Hatası", message: error.localizedDescription)
                            return
                        }

                        guard let userId = authResult?.user.uid else { return }

                        // Firestore'a ek bilgi kaydetmek
                        let db = Firestore.firestore()
                        db.collection("users").document(userId).setData([
                            "email": email.lowercased(),
                            "firstName": firstName,
                            "lastName": lastName,
                            "username": username.lowercased(),
                            "createdAt": Date(),
                            "followers": [],
                            "following": []
                        ]) { error in
                            if let error = error {
                                self.showAlert(title: "Veritabanı Hatası", message: error.localizedDescription)
                            } else {
                                print("Kullanıcı bilgileri Firestore'a kaydedildi!")
                                self.navigateToProfile(username: username.lowercased())
                            }
                        }
                    }
                } else {
                    self.showAlert(title: "Hata", message: "Bu kullanıcı adı zaten alınmış.")
                }
            }
        }
    }

    func isUsernameUnique(_ username: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isEqualTo: username.lowercased()) // Kullanıcı adı kontrolünde küçük harf kullanımı
            .getDocuments(source: .server) { snapshot, error in // Server'dan sorgula
                if let error = error {
                    print("Kullanıcı adı kontrolü hatası: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                // Eğer dönen belge varsa, kullanıcı adı daha önce alınmış demektir.
                if let documents = snapshot?.documents, !documents.isEmpty {
                    print("Kullanıcı adı zaten alınmış: \(username)")
                    completion(false) // Kullanıcı adı zaten var
                } else {
                    print("Kullanıcı adı benzersiz: \(username)")
                    completion(true) // Kullanıcı adı benzersiz
                }
            }
    }


    
    // Profil sayfasına yönlendirme fonksiyonu
    private func navigateToProfile(username: String) {
        let profileVC = ProfileViewController(username: username)
        profileVC.modalPresentationStyle = .fullScreen
        self.present(profileVC, animated: true, completion: nil)
    }
    
    // Geri butonuna tıklanma işlemi
    @objc private func backTapped() {
        self.dismiss(animated: true, completion: nil) // Gerçekten geri gitmek için modally dismiss
    }
    
    // Basit bir alert fonksiyonu
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
