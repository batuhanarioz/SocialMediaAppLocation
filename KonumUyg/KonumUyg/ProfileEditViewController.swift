//
//  ProfileEditViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//


import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import Cloudinary

protocol ProfileEditDelegate: AnyObject {
    func didUpdateProfilePhoto()
}

class ProfileEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: ProfileEditDelegate?
    
    // Bilgi başlıkları ve bilgilerin çekildiği labellar
       private let firstNameLabel = UILabel()
       private let firstNameValueLabel = UILabel()
       private let lastNameLabel = UILabel()
       private let lastNameValueLabel = UILabel()
       private let usernameLabel = UILabel()
       private let usernameValueLabel = UILabel()
       private let descriptionLabel = UILabel()
       private let descriptionValueLabel = UILabel()
       private let passwordLabel = UILabel()
       private let passwordValueLabel = UILabel()
    private let privacySwitchLabel = UILabel()
    private let privacySwitch = UISwitch()
    private let deleteAccountButton = UIButton(type: .system)

    // Görsel yükleme ve avatar resmi gösterme
    private let avatarImageView = UIImageView()
    private let uploadPhotoButton = UIButton(type: .system)
    
    let cloudName: String = "<dbnojset9>"
    
    private var currentUser: FirebaseAuth.User?  // FirebaseAuth.User olarak değiştirildi
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        // Fetch user data
        fetchUserData()
        loadAvatarFromFirestore()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUserData), name: Notification.Name("UserDataUpdated"), object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("UserDataUpdated"), object: nil)
    }

    private func createLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func setupUI() {
        // Profil fotoğrafı ve yükleme butonu
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.clipsToBounds = true
        view.addSubview(avatarImageView)
        
            uploadPhotoButton.setTitle("Fotoğraf Yükle", for: .normal)
            uploadPhotoButton.addTarget(self, action: #selector(uploadPhotoTapped), for: .touchUpInside)
            uploadPhotoButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(uploadPhotoButton)

            // Bilgi alanları için başlık ve değerler
            setupLabel(firstNameLabel, text: "Ad")
            setupLabel(lastNameLabel, text: "Soyad")
            setupLabel(usernameLabel, text: "Kullanıcı Adı")
            setupLabel(descriptionLabel, text: "Açıklama")
            setupLabel(passwordLabel, text: "Şifre")

            // Bilgilerin görüntülenmesi
            setupValueLabel(firstNameValueLabel, action: #selector(editFirstName))
            setupValueLabel(lastNameValueLabel, action: #selector(editLastName))
            setupValueLabel(usernameValueLabel, action: #selector(editUsername))
            setupValueLabel(descriptionValueLabel, action: #selector(editDescription))
            setupValueLabel(passwordValueLabel, action: #selector(editPassword))
            
            passwordValueLabel.text = "••••••••" // Şifreyi nokta şeklinde göster

            setupConstraints()
        setupPrivacySettingsUI() // Gizlilik ayarları kısmını ekleyelim
        
        deleteAccountButton.setTitle("Hesabı Sil", for: .normal)
            deleteAccountButton.setTitleColor(.red, for: .normal)  // Kırmızı renk
            deleteAccountButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)  // Yazı fontunu büyütüyoruz
            deleteAccountButton.translatesAutoresizingMaskIntoConstraints = false
            deleteAccountButton.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
            view.addSubview(deleteAccountButton)
            
            // Butonu sayfanın en altına yerleştiriyoruz
            NSLayoutConstraint.activate([
                deleteAccountButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                deleteAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                deleteAccountButton.widthAnchor.constraint(equalToConstant: 200),  // Buton genişliği
                deleteAccountButton.heightAnchor.constraint(equalToConstant: 50)  // Buton yüksekliği
            ])

    }
    
    private func setupPrivacySettingsUI() {
        // "Hesabı gizli profil olarak düzenle." etiketi
        privacySwitchLabel.text = "Hesabı gizli profil olarak düzenle."
        privacySwitchLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        privacySwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(privacySwitchLabel)
        
        // Switch buton
        privacySwitch.translatesAutoresizingMaskIntoConstraints = false
        privacySwitch.addTarget(self, action: #selector(privacySwitchToggled), for: .valueChanged)
        view.addSubview(privacySwitch)
        
        // Layout constraint'larını ekleyelim
        NSLayoutConstraint.activate([
            privacySwitchLabel.topAnchor.constraint(equalTo: passwordValueLabel.bottomAnchor, constant: 30),
            privacySwitchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            privacySwitch.centerYAnchor.constraint(equalTo: privacySwitchLabel.centerYAnchor),
            privacySwitch.leadingAnchor.constraint(equalTo: privacySwitchLabel.trailingAnchor, constant: 10),
        ])
    }
    
    @objc private func privacySwitchToggled() {
        if privacySwitch.isOn {
            print("Hesap gizli profil olarak düzenlendi.")
        } else {
            print("Hesap herkese açık olarak düzenlendi.")
        }
    }


    private func setupLabel(_ label: UILabel, text: String) {
            label.text = text
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
        }

    private func setupValueLabel(_ label: UILabel, action: Selector) {
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemBlue
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        label.addGestureRecognizer(tapGesture)
        view.addSubview(label)
    }

    private func setupConstraints() {
        // Avatar ImageView ve Fotoğraf Yükle Butonu
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),

            uploadPhotoButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            uploadPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Sol tarafta etiketler ve sağda değerler
            firstNameLabel.topAnchor.constraint(equalTo: uploadPhotoButton.bottomAnchor, constant: 30),
            firstNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            firstNameValueLabel.centerYAnchor.constraint(equalTo: firstNameLabel.centerYAnchor),
            firstNameValueLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            lastNameLabel.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 20),
            lastNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            lastNameValueLabel.centerYAnchor.constraint(equalTo: lastNameLabel.centerYAnchor),
            lastNameValueLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            usernameLabel.topAnchor.constraint(equalTo: lastNameLabel.bottomAnchor, constant: 20),
            usernameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            usernameValueLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            usernameValueLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            descriptionLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            descriptionValueLabel.centerYAnchor.constraint(equalTo: descriptionLabel.centerYAnchor),
            descriptionValueLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            
            passwordLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            passwordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            passwordValueLabel.centerYAnchor.constraint(equalTo: passwordLabel.centerYAnchor),
            passwordValueLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
        ])
    }


    // Verileri Firestore'dan çeken fonksiyon
    @objc private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { (document, error) in
            if let error = error {
                print("Veri alınırken hata oluştu: \(error.localizedDescription)")
            } else if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    // Firebase'den alınan veriyi etiketlere yansıtıyoruz
                    self.firstNameValueLabel.text = data["firstName"] as? String ?? "Ad yok"
                    self.lastNameValueLabel.text = data["lastName"] as? String ?? "Soyad yok"
                    self.usernameValueLabel.text = data["username"] as? String ?? "Kullanıcı Adı yok"
                    self.descriptionValueLabel.text = data["description"] as? String ?? "Açıklama yok"
                }
            }
        }
    }

    
    // UI üzerinde değerlerin bulunduğu etiketlere tıklandığında hangi metotların çalışacağını belirleyelim
    @objc func editFirstName() {
        let editVC = EditFirstNameViewController() // Ad düzenleme sayfası
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc func editLastName() {
        let editVC = EditLastNameViewController() // Soyad düzenleme sayfası
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc func editUsername() {
        let editVC = EditUsernameViewController() // Kullanıcı adı düzenleme sayfası
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc func editDescription() {
        let editVC = EditDescriptionViewController() // Açıklama düzenleme sayfası
        navigationController?.pushViewController(editVC, animated: true)
    }

    @objc func editPassword() {
        let editVC = EditPasswordViewController() // Şifre düzenleme sayfası
        navigationController?.pushViewController(editVC, animated: true)
    }

    private func updateFirestoreWithNewData(_ updatedData: [String: Any]) {
        guard let user = currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).updateData(updatedData) { error in
            if let error = error {
                print("Veri güncellenemedi: \(error.localizedDescription)")
            } else {
                print("Veri başarıyla güncellendi")
            }
        }
    }
    
    @objc private func deleteAccountTapped() {
            // Hesabı silme işlemi için bir alert penceresi açılıyor
            let alertController = UIAlertController(title: "Hesabınızı Silmek Üzeresiniz",
                                                    message: "Hesabınızı tamamen silmek istediğinize emin misiniz?",
                                                    preferredStyle: .alert)
            
            // Şifre girişi için bir textField ekliyoruz
            alertController.addTextField { textField in
                textField.placeholder = "Şifrenizi girin"
                textField.isSecureTextEntry = true
            }
            
            // "Evet" butonu
            let yesAction = UIAlertAction(title: "Evet", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                
                // TextField'dan şifreyi alıyoruz
                if let password = alertController.textFields?.first?.text {
                    self.verifyPasswordAndDeleteAccount(password: password)
                }
            }
            
            // "Hayır" butonu
            let noAction = UIAlertAction(title: "Hayır", style: .cancel, handler: nil)
            
            // Butonları alert'e ekliyoruz
            alertController.addAction(yesAction)
            alertController.addAction(noAction)
            
            // Alert'i gösteriyoruz
            present(alertController, animated: true, completion: nil)
        }

        private func verifyPasswordAndDeleteAccount(password: String) {
            guard let user = Auth.auth().currentUser else { return }
            
            // Kullanıcı şifresini doğrulamak için re-authenticate ediyoruz
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: password)
            
            user.reauthenticate(with: credential) { [weak self] result, error in
                if let error = error {
                    print("Şifre doğrulama hatası: \(error.localizedDescription)")
                    self?.showErrorMessage("Şifre yanlış. Lütfen tekrar deneyin.")
                    return
                }
                
                // Şifre doğrulandıysa, hesabı siliyoruz
                self?.deleteUserAccount()
            }
        }

        private func deleteUserAccount() {
            guard let user = Auth.auth().currentUser else { return }
            
            // Firestore'dan kullanıcı verilerini silme
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).delete { [weak self] error in
                if let error = error {
                    print("Kullanıcı verileri silinemedi: \(error.localizedDescription)")
                    self?.showErrorMessage("Kullanıcı verileri silinemedi.")
                } else {
                    print("Kullanıcı verileri başarıyla silindi.")
                    
                    // Firebase Authentication'dan kullanıcıyı silme
                    user.delete { error in
                        if let error = error {
                            print("Hesap silinemedi: \(error.localizedDescription)")
                            self?.showErrorMessage("Hesap silinemedi.")
                        } else {
                            print("Hesap başarıyla silindi.")
                            self?.handleUserDeleted()
                        }
                    }
                }
            }
        }

        private func showErrorMessage(_ message: String) {
            let alertController = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Tamam", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }

        private func handleUserDeleted() {
            // Kullanıcı silindikten sonra yapılacak işlemler
            // Örneğin: Giriş ekranına yönlendirme
            let loginVC = LoginViewController()  // Login ekranınızı burada belirtebilirsiniz
            self.navigationController?.setViewControllers([loginVC], animated: true)
        }

    // MARK: - Image
    
    @objc func uploadPhotoTapped() {
        // Fotoğraf seçmek için bir UIImagePickerController açılıyor
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }

    // Fotoğraf seçildikten sonra işlemler yapılacak
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }

        // Resmi, yuvarlak bir şekilde gösteriyoruz
        avatarImageView.image = selectedImage
        setCircularImage(imageView: avatarImageView, image: selectedImage)

        // Resmi Cloudinary'e yüklemek
        uploadAvatarImageToCloudinary(image: selectedImage) { imageUrl in
            if let imageUrl = imageUrl {
                self.saveUserAvatarUrl(imageUrl)
                self.loadAvatarImage(from: imageUrl)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }

    func uploadAvatarImageToCloudinary(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            print("Resim Data'ya çevrilemedi.")
            return
        }

        let uploadPreset = "m2bpnzka"
        CloudinaryManager.shared.createUploader().upload(data: imageData, uploadPreset: uploadPreset, completionHandler: { (result, error) in
            if let error = error {
                print("Resim yüklenemedi: \(error.localizedDescription)")
                completion(nil)
            } else if let result = result {
                completion(result.secureUrl)
                // Fotoğraf başarıyla yüklendiğinde delegate üzerinden bildirim gönder
                self.delegate?.didUpdateProfilePhoto()
            }
        })
    }


    func saveUserAvatarUrl(_ imageUrl: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).updateData(["avatarUrl": imageUrl]) { error in
            if let error = error {
                print("Avatar URL kaydedilemedi: \(error.localizedDescription)")
            }
        }
    }

    func loadAvatarImage(from urlString: String) {
        guard let avatarUrl = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: avatarUrl) { (data, _, error) in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.avatarImageView.image = image
                    self.setCircularImage(imageView: self.avatarImageView, image: image)
                }
            }
        }
        task.resume()
    }

    func loadAvatarFromFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        db.collection("users").document(user.uid).getDocument { (document, _) in
            if let document = document, let data = document.data(), let avatarUrl = data["avatarUrl"] as? String {
                self.loadAvatarImage(from: avatarUrl)
            }
        }
    }

    func setCircularImage(imageView: UIImageView, image: UIImage) {
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
        imageView.image = image
    }

}

extension UIImageView {
    func setCircularImage(image: UIImage) {
        self.image = image
        self.layer.cornerRadius = self.frame.size.width / 2
        self.clipsToBounds = true
    }
}
