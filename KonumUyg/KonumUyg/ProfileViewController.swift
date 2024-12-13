//
//  ProfileViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    func didUpdateProfilePhoto() {
            // Fotoğraf güncellendiği için Firestore'dan yeniden yükleyin
        loadUserProfileImage()
        }
    
    private let searchBar = UISearchBar()
    private let searchIconButton = UIButton() // UIBarButtonItem yerine UIButton kullanıyoruz
    private var isSearchActive = false
    private var usernames: [String] = []
    private var filteredUsernames: [String] = []
    private let tableView = UITableView()
    
    private var username: String
    private var avatarImageView = UIImageView()
    private var usernameLabel = UILabel()
    private var followersLabel = UILabel()
    private var followingLabel = UILabel()
    private var editButton = UIButton()
    private var descriptionLabel = UILabel()
        
    private var followersContainer = UIView()
    private var followingContainer = UIView()
    
        
        // Gerekli initializer
        init(username: String) {
            self.username = username
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var userUID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupOptionsButton()  // Butonun eklenmesini sağlayın
        fetchUserProfileData()
        loadUserProfileImage() // Avatar resmi yükleniyor

        // Search icon'u view üzerine ekleyelim
        setupSearchIconButton()
        
        // Tap gesture ekleyerek boş alana tıklayınca klavyeyi kapat
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Bu, tableView seçimlerini etkilemesini engeller
        view.addGestureRecognizer(tapGesture)
        
        searchBar.delegate = self // Delegate ayarlandı
        searchBar.showsCancelButton = true
        // Örneğin, viewDidLoad’da şu ayarı yapın:
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        print("TableView Çerçevesi: \(tableView.frame)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Eğer navigationController varsa, büyük başlıkları devre dışı bırak
        if let navController = navigationController {
            navController.navigationBar.prefersLargeTitles = false
            print("Navigation controller found")
        } else {
            print("No navigation controller found")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfileImage() // Profil fotoğrafı güncellenmesini sağlar
        fetchUserProfileData()
        loadNewUsername()
        loadNewDescription()
    }
    
    // Firebase'den kullanıcı adını çeken ve UI'yi güncelleyen fonksiyon
        func loadNewUsername() {
            guard let userUID = Auth.auth().currentUser?.uid else {
                print("User not logged in")
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(userUID).getDocument { [weak self] (document, error) in
                if let error = error {
                    print("Error fetching username: \(error.localizedDescription)")
                } else if let document = document, document.exists {
                    // Kullanıcı adı varsa UI'yi güncelle
                    if let username = document.get("username") as? String {
                        // Burada usernameLabel'ı doğrudan güncelliyoruz
                        self?.usernameLabel.text = username
                    }
                }
            }
        }
    
    func loadNewDescription() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userUID).getDocument { [weak self] (document, error) in
            if let error = error {
                print("Error fetching description: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                // Açıklama varsa UI'yi güncelle
                if let description = document.get("description") as? String {
                    // Burada descriptionLabel'ı doğrudan güncelliyoruz
                    self?.descriptionLabel.text = description
                }
            }
        }
    }

    
    // Firebase kullanıcı adı çekme
        private func fetchUserProfileData() {
            let db = Firestore.firestore()

            // Kullanıcı bilgilerini çek
            db.collection("users").whereField("username", isEqualTo: username).getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching user profile data: \(error.localizedDescription)")
                    return
                }

                guard let document = snapshot?.documents.first else { return }
                let data = document.data()

                // Avatar URL'sini kontrol et ve yükle
                if let avatarUrl = data["avatarUrl"] as? String {
                    self?.avatarImageView.loadImage(from: avatarUrl)
                }

                // Kullanıcı adını kontrol et ve yükle
                if let username = data["username"] as? String {
                    self?.usernameLabel.text = username  // Username'i label'a atıyoruz
                }

                // Takipçi ve Takip Edilenler
                let followers = data["followers"] as? [String] ?? []
                let following = data["following"] as? [String] ?? []

                self?.followersLabel.text = "Takipçi \(followers.count)"
                self?.followingLabel.text = "Takip Edilen \(following.count)"

                // Eğer takipçi veya takip edilen yoksa 0 göster
                if followers.isEmpty {
                    self?.followersLabel.text = "Takipçi 0"
                }
                if following.isEmpty {
                    self?.followingLabel.text = "Takip Edilen 0"
                }

                // Açıklama ekleyelim
                if let description = data["description"] as? String, !description.isEmpty {
                    self?.descriptionLabel.text = description
                    self?.descriptionLabel.isHidden = false // Açıklama varsa, label'ı görünür yap
                } else {
                    self?.descriptionLabel.text = "No description available"  // Varsayılan metin ekleyebiliriz
                    self?.descriptionLabel.isHidden = true  // Açıklama yoksa, label'ı yine görünür tutabiliriz
                }

            }
        }

        private func loadUserProfileImage() {
            // Kullanıcının avatar URL'sini Firestore'dan alıyoruz
            guard let userUID = Auth.auth().currentUser?.uid else { return }

            let db = Firestore.firestore()
            db.collection("users").document(userUID).getDocument { [weak self] (document, error) in
                if let error = error {
                    print("Error fetching profile image: \(error.localizedDescription)")
                    return
                }

                // Avatar URL'si varsa resmi yükle, yoksa person.circle simgesini göster
                if let document = document, let data = document.data() {
                    if let avatarUrl = data["avatarUrl"] as? String, !avatarUrl.isEmpty {
                        self?.avatarImageView.loadImage(from: avatarUrl)
                    } else {
                        self?.avatarImageView.image = UIImage(systemName: "person.circle") // Default image
                    }
                }
            }
        }


    private func setupUI() {
                view.backgroundColor = .white
                
        // Avatar ImageView
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.translatesAutoresizingMaskIntoConstraints = false
            avatarImageView.layer.cornerRadius = 50 // Yuvarlak yapmak için kenar yarıçapı
            avatarImageView.layer.masksToBounds = true // Kenarların düzgün görünmesi için
            view.addSubview(avatarImageView)

                // Username Label
                usernameLabel.font = UIFont.systemFont(ofSize: 18)
                usernameLabel.textColor = .black
                usernameLabel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(usernameLabel)

                // Takipçi ve Takip Edilen Container'ları
                followersContainer.translatesAutoresizingMaskIntoConstraints = false
                followersContainer.layer.borderWidth = 1
                followersContainer.layer.borderColor = UIColor.gray.cgColor
                followersContainer.layer.cornerRadius = 5
                followersContainer.isUserInteractionEnabled = true  // Tıklanabilir hale getir
                followersContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(followersTapped)))
                view.addSubview(followersContainer)
        
                followingContainer.translatesAutoresizingMaskIntoConstraints = false
                followingContainer.layer.borderWidth = 1
                followingContainer.layer.borderColor = UIColor.gray.cgColor
                followingContainer.layer.cornerRadius = 5
                followingContainer.isUserInteractionEnabled = true  // Tıklanabilir hale getir
                followingContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(followingTapped)))
                view.addSubview(followingContainer)
        
                // Takipçi ve Takip Edilen etiketleri
                followersLabel.font = UIFont.systemFont(ofSize: 16)
                followersLabel.textColor = .black
                followersLabel.translatesAutoresizingMaskIntoConstraints = false
                followersContainer.addSubview(followersLabel)

                followingLabel.font = UIFont.systemFont(ofSize: 16)
                followingLabel.textColor = .black
                followingLabel.translatesAutoresizingMaskIntoConstraints = false
                followingContainer.addSubview(followingLabel)

                // Açıklama etiketi
                descriptionLabel.font = UIFont.systemFont(ofSize: 16)
                descriptionLabel.textColor = .black
                descriptionLabel.numberOfLines = 0
                descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(descriptionLabel)

                // Takip et butonu
                editButton.setTitle("Profili Düzenle", for: .normal)
                editButton.backgroundColor = .blue
                editButton.tintColor = .white
                editButton.translatesAutoresizingMaskIntoConstraints = false
                editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
                view.addSubview(editButton)
        

                // Constraints
                NSLayoutConstraint.activate([
                    avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
                    avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    avatarImageView.widthAnchor.constraint(equalToConstant: 100),
                    avatarImageView.heightAnchor.constraint(equalToConstant: 100),

                    usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
                    usernameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

                    // Takipçi ve Takip Edilen container'ları
                    followersContainer.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 20),
                    followersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
                    followersContainer.widthAnchor.constraint(equalToConstant: 150),
                    followersContainer.heightAnchor.constraint(equalToConstant: 50),

                    followingContainer.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 20),
                    followingContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
                    followingContainer.widthAnchor.constraint(equalToConstant: 150),
                    followingContainer.heightAnchor.constraint(equalToConstant: 50),

                    followersLabel.centerXAnchor.constraint(equalTo: followersContainer.centerXAnchor),
                    followersLabel.centerYAnchor.constraint(equalTo: followersContainer.centerYAnchor),

                    followingLabel.centerXAnchor.constraint(equalTo: followingContainer.centerXAnchor),
                    followingLabel.centerYAnchor.constraint(equalTo: followingContainer.centerYAnchor),

                    // Açıklama etiketi
                    descriptionLabel.topAnchor.constraint(equalTo: followersContainer.bottomAnchor, constant: 20),
                    descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
                    descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

                    // Takip et butonu
                    editButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
                    editButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    editButton.widthAnchor.constraint(equalToConstant: 200),
                    editButton.heightAnchor.constraint(equalToConstant: 50),
                    
                ])
        
        // Search bar setup
        searchBar.delegate = self
        searchBar.placeholder = "Kullanıcı Ara"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.isHidden = true // Başlangıçta gizli
        searchBar.showsScopeBar = false // Search bar öneri listesi engellendi
        searchBar.autocorrectionType = .no // Autocorrection engellendi
        searchBar.autocapitalizationType = .none // Büyük harf otomatik düzeltmesi engellendi
        view.addSubview(searchBar)
        
        // Table view setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true // Başlangıçta gizli
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    let optionsButton = UIButton()
    
    private func setupOptionsButton() {
        // Options button'u ekleyelim
        optionsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        optionsButton.tintColor = .black
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        view.addSubview(optionsButton)
        
        // Options button'un sağ üst köşeye konumlandırılması
        NSLayoutConstraint.activate([
            optionsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            optionsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), // Sağ tarafa konumlandırma
            optionsButton.widthAnchor.constraint(equalToConstant: 30),
            optionsButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func optionsButtonTapped() {
        let optionsVC = OptionsViewController()  // OptionsViewController UIViewController olmalı
        navigationController?.pushViewController(optionsVC, animated: true)
    }


    
    @objc private func followersTapped() {
        // Takipçi listesini gösterecek sayfaya yönlendir
        let followersViewController = FollowersController()  // Yeni bir ekran açalım
        navigationController?.pushViewController(followersViewController, animated: true)
    }

    @objc private func followingTapped() {
        // Takip edilen listesini gösterecek sayfaya yönlendir
        let followingViewController = FollowingController()  // Yeni bir ekran açalım
        navigationController?.pushViewController(followingViewController, animated: true)
    }

    
    private func setupSearchIconButton() {
        // Search icon'u UIButton olarak ekleyelim
        searchIconButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchIconButton.tintColor = .black
        searchIconButton.translatesAutoresizingMaskIntoConstraints = false
        searchIconButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        view.addSubview(searchIconButton)
        
        // Search icon'un sol tarafta konumlandırılması
        NSLayoutConstraint.activate([
            searchIconButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchIconButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), // Sol tarafa konumlandırma
            searchIconButton.widthAnchor.constraint(equalToConstant: 30),
            searchIconButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func showLoginPage() {
        // Giriş sayfasına yönlendirme
        if let window = view.window {
            let loginVC = LoginViewController() // Giriş ekranı controller'ını burada belirleyin
            let navigationController = UINavigationController(rootViewController: loginVC)
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }
    
    private func fetchUsernames(searchText: String) {
        let db = Firestore.firestore()
        
        db.collection("users").whereField("username", isGreaterThanOrEqualTo: searchText).whereField("username", isLessThanOrEqualTo: searchText + "\u{f8ff}").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching usernames: \(error.localizedDescription)")
                return
            }

            self?.usernames = snapshot?.documents.compactMap { document in
                return document.get("username") as? String
            } ?? []
            
            self?.filteredUsernames = self?.usernames.filter { $0.lowercased().contains(searchText.lowercased()) } ?? []
            self?.tableView.reloadData()
        }
    }
    
    func goToProfile(username: String) {
        print("goToProfile çağrıldı, kullanıcı: \(username)")
        guard let navigationController = navigationController else {
            print("NavigationController mevcut değil.")
            return
        }
        let profileVC = ProfileDetailViewController(username: username)
        print("Profil ekranına yönlendiriliyor: \(username)")
        navigationController.pushViewController(profileVC, animated: true)
    }


    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchUsernames(searchText: searchText) // Firebase'den kullanıcıları çek
        print("Filtrelenmiş Kullanıcılar: \(filteredUsernames)") // Filtrelenmiş kullanıcıları yazdır
        tableView.reloadData()
    }
    
    @objc private func searchButtonTapped() {
            // Search icon tıklandığında searchBar ve tableView gösterilir, search icon gizlenir
        optionsButton.isHidden = true  // Seçenekler butonunu gizliyoruz
        searchBar.isHidden = false
        tableView.isHidden = false
        searchIconButton.isHidden = true
        searchBar.becomeFirstResponder() // Klavye açılır
    }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            // Cancel butonuna tıklanınca searchBar ve tableView tamamen gizlenir, search icon görünür hale gelir
            optionsButton.isHidden = false  // Seçenekler butonunu görünür kılıyoruz
            searchBar.isHidden = true
            tableView.isHidden = true
            searchIconButton.isHidden = false
            searchBar.text = ""
            searchBar.resignFirstResponder() // Klavye kapanır
        }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true) // Klavyeyi kapatır
        searchBar.resignFirstResponder() // Search bar'ı daaktif hale getirir
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") ?? UITableViewCell(style: .default, reuseIdentifier: "UserCell")
        let username = filteredUsernames[indexPath.row]
        cell.textLabel?.text = username
        print("Hücreye atanan kullanıcı adı: \(username)")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Hücre seçildi: \(indexPath.row)")
        let selectedUsername = filteredUsernames[indexPath.row]
        goToProfile(username: selectedUsername)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    @objc private func editButtonTapped() {
        let profileEditVC = ProfileEditViewController()
        navigationController?.pushViewController(profileEditVC, animated: true)
    }


    
   
}



extension UIImageView {
    func loadImage(from urlString: String) {
        // Eğer göstergeyi eklemediyseniz, göstergemizi hazırlayalım
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = self.center // Activity Indicator'ı resmin ortasına yerleştiriyoruz
        activityIndicator.hidesWhenStopped = true  // Gösterge durduğunda kaybolsun
        self.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()  // Göstergeyi başlat

        // URL geçerliliğini kontrol et
        guard let url = URL(string: urlString) else {
            // Eğer geçerli bir URL değilse varsayılan 'person.circle' simgesini göster
            self.image = UIImage(systemName: "person.circle")
            activityIndicator.stopAnimating()  // Göstergeyi durdur
            return
        }
        
        // Asenkron veri çekme işlemi
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            // Hata durumunda veya veri alınamazsa varsayılan resmi göster
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.image = UIImage(systemName: "person.circle")  // Hata durumunda varsayılan resim
                    activityIndicator.stopAnimating()  // Göstergeyi durdur
                }
                return
            }
            
            // Eğer veri varsa ve hata yoksa, resim verisini işle
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image  // Asenkron olarak UI güncelleniyor
                    activityIndicator.stopAnimating()  // Göstergeyi durdur
                }
            } else {
                // Eğer veri yoksa, yine varsayılan resim göster
                DispatchQueue.main.async {
                    self.image = UIImage(systemName: "person.circle")
                    activityIndicator.stopAnimating()  // Göstergeyi durdur
                }
            }
        }.resume()
    }
}


