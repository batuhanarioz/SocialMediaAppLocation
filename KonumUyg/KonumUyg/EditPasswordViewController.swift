//
//  EditPasswordViewController.swift
//  KonumUyg
//
//  Created by reel on 14.11.2024.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

class EditPasswordViewController: UIViewController {
    
    private let oldPasswordLabel = UILabel()
    private let oldPasswordTextField = UITextField()
    
    private let newPasswordLabel = UILabel()
    private let newPasswordTextField = UITextField()
    
    private let confirmPasswordLabel = UILabel()
    private let confirmPasswordTextField = UITextField()
    
    private let errorMessageLabel = UILabel()
    
    private let saveButton = UIButton(type: .system)
    
    private var currentUser: FirebaseAuth.User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Şifre Düzenle"
        
        currentUser = FirebaseAuth.Auth.auth().currentUser
        setupUI()
    }
    
    private func setupUI() {
        // Eski şifre label ve text field
        oldPasswordLabel.text = "Eski Şifre"
        oldPasswordLabel.font = UIFont.systemFont(ofSize: 16)
        oldPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(oldPasswordLabel)
        
        oldPasswordTextField.placeholder = "Eski şifrenizi girin"
        oldPasswordTextField.isSecureTextEntry = true
        oldPasswordTextField.borderStyle = .roundedRect
        oldPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(oldPasswordTextField)
        
        // Yeni şifre label ve text field
        newPasswordLabel.text = "Yeni Şifre"
        newPasswordLabel.font = UIFont.systemFont(ofSize: 16)
        newPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPasswordLabel)
        
        newPasswordTextField.placeholder = "Yeni şifrenizi girin"
        newPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.borderStyle = .roundedRect
        newPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPasswordTextField)
        
        // Yeni şifre label ve text field
        newPasswordLabel.text = "Yeni Şifre"
        newPasswordLabel.font = UIFont.systemFont(ofSize: 16)
        newPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPasswordLabel)
        
        newPasswordTextField.placeholder = "Yeni şifrenizi tekrar girin"
        newPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.borderStyle = .roundedRect
        newPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPasswordTextField)
        
        // Hata mesajı label
        errorMessageLabel.textColor = .red
        errorMessageLabel.font = UIFont.systemFont(ofSize: 14)
        errorMessageLabel.text = ""
        errorMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorMessageLabel)
        
        // Kaydet butonu
        saveButton.setTitle("Kaydet", for: .normal)
        saveButton.addTarget(self, action: #selector(updatePasswordTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Eski Şifre
            oldPasswordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            oldPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            oldPasswordTextField.topAnchor.constraint(equalTo: oldPasswordLabel.bottomAnchor, constant: 10),
            oldPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            oldPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Yeni Şifre
            newPasswordLabel.topAnchor.constraint(equalTo: oldPasswordTextField.bottomAnchor, constant: 30),
            newPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            newPasswordTextField.topAnchor.constraint(equalTo: newPasswordLabel.bottomAnchor, constant: 10),
            newPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            newPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            confirmPasswordLabel.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 30),
            confirmPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            confirmPasswordTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor, constant: 10),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Hata Mesajı
            errorMessageLabel.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 10),
            errorMessageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorMessageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Kaydet Butonu
            saveButton.topAnchor.constraint(equalTo: errorMessageLabel.bottomAnchor, constant: 30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func updatePasswordTapped() {
            guard let oldPassword = oldPasswordTextField.text, !oldPassword.isEmpty,
                  let newPassword = newPasswordTextField.text, !newPassword.isEmpty,
                  let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
                showError("Lütfen tüm alanları doldurun.")
                return
            }
            
            // Yeni şifre ile onay şifresinin eşleşip eşleşmediğini kontrol et
            if newPassword != confirmPassword {
                showError("Yeni şifreler uyuşmuyor.")
                return
            }
            
            // Mevcut şifreyi doğrulama ve şifreyi değiştirme
            reAuthenticateUser(oldPassword: oldPassword) { [weak self] success in
                if success {
                    self?.updatePassword(newPassword: newPassword)
                } else {
                    self?.showError("Eski şifreniz yanlış.")
                }
            }
        }

        private func reAuthenticateUser(oldPassword: String, completion: @escaping (Bool) -> Void) {
            guard let user = Auth.auth().currentUser else {
                completion(false)
                return
            }
            
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: oldPassword)
            
            user.reauthenticate(with: credential) { (result, error) in
                if let error = error {
                    print("Re-authentication failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }

        private func updatePassword(newPassword: String) {
            guard let user = Auth.auth().currentUser else { return }
            
            user.updatePassword(to: newPassword) { [weak self] error in
                if let error = error {
                    self?.showError("Şifre güncellenirken hata oluştu: \(error.localizedDescription)")
                } else {
                    self?.showSuccess("Şifre başarıyla güncellendi!")
                }
            }
        }

        private func showError(_ message: String) {
            let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
        }

        private func showSuccess(_ message: String) {
            let alert = UIAlertController(title: "Başarılı", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }

}
