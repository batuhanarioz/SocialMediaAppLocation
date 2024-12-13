//
//  ProfileDetailViewController.swift
//  KonumUyg
//
//  Created by reel on 12.11.2024.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class ProfileDetailViewController: UIViewController {

    private var username: String
    private var avatarImageView = UIImageView()
    private var usernameLabel = UILabel()
    private var followersLabel = UILabel()
    private var followingLabel = UILabel()
    private var descriptionLabel = UILabel()

    private var followersContainer = UIView()
    private var followingContainer = UIView()
    
    private var followButton = UIButton()
    
    // Takipçi ve takip edilenlerin kullanıcı adlarını saklamak için diziler
    private var followersUsernames: [String] = []
    private var followingUsernames: [String] = []

    init(username: String) {
        self.username = username
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserProfileImage() // Profil fotoğrafı güncellenmesini sağlar
        fetchUserProfileData()
        loadNewUsername()
        loadNewDescription()
        print("Profil sayfası: \(username)'a yönlendirildiniz.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfileImage() // Profil fotoğrafı güncellenmesini sağlar
        fetchUserProfileData()
        loadNewUsername()
        loadNewDescription()
    }

    private func setupUI() {
        view.backgroundColor = .white

        // Avatar ImageView
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 50 // Yuvarlak kenar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)

        // Username Label
        usernameLabel.font = UIFont.boldSystemFont(ofSize: 20)
        usernameLabel.textColor = .black
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(usernameLabel)

        // Takipçi ve Takip edilenler container'ları
        followersContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(followersContainer)

        followingContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(followingContainer)

        // Takipçi ve Takip edilenler etiketleri
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
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // Takip et butonunu ekleyelim
           followButton.setTitle("Takip Et", for: .normal)
           followButton.backgroundColor = .blue
           followButton.layer.cornerRadius = 8
           followButton.translatesAutoresizingMaskIntoConstraints = false
           followButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
           view.addSubview(followButton)

        // Constraints
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),

            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            usernameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

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

            descriptionLabel.topAnchor.constraint(equalTo: followingContainer.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            followButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            followButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            followButton.widthAnchor.constraint(equalToConstant: 200),
            followButton.heightAnchor.constraint(equalToConstant: 50),
        ])
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

    private func loadUserProfileImage() {
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).getDocument(source: .default) { [weak self] (document, error) in
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
                return
            }

            if let document = document, let avatarUrl = document.get("avatarUrl") as? String {
                self?.avatarImageView.loadImage(from: avatarUrl)
            } else {
                print("No avatar URL found.")
                self?.avatarImageView.image = UIImage(systemName: "person.circle")
            }
        }
    }

    private func fetchUserProfileData() {
        let db = Firestore.firestore()

        db.collection("users").whereField("username", isEqualTo: username).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user profile data: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("No user document found.")
                return
            }

            let data = document.data()
            let followedUserUID = document.documentID

            // Kullanıcı bilgilerini yükle
            self.populateProfileDetails(from: data)

            // Takip durumunu kontrol et
            self.isFollowing(followedUserUID: followedUserUID) { [weak self] isFollowing in
                self?.updateFollowButton(isFollowing: isFollowing)
            }

            // Takip isteği durumu
            if let isPrivate = data["isPrivate"] as? Bool, isPrivate {
                self.checkFollowRequestStatus(followedUserUID: followedUserUID)
            }

            // Takipçi ve takip edilen sayısını getir
            self.fetchFollowersAndFollowing(followedUserUID: followedUserUID)
        }
    }
    
    private func populateProfileDetails(from data: [String: Any]) {
        if let avatarUrl = data["avatarUrl"] as? String {
            avatarImageView.loadImage(from: avatarUrl)
        }
        if let username = data["username"] as? String {
            usernameLabel.text = username
        }
        if let description = data["description"] as? String {
            descriptionLabel.text = description
        }
    }

    private func fetchFollowersAndFollowing(followedUserUID: String) {
        let db = Firestore.firestore()
        db.collection("users").document(followedUserUID).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching followers and following data: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data() {
                let followers = data["followers"] as? [String] ?? []
                let following = data["following"] as? [String] ?? []

                self?.followersLabel.text = "Takipçi \(followers.count)"
                self?.followingLabel.text = "Takip Edilen \(following.count)"
            }
        }
    }



    
    private func checkFollowRequestStatus(followedUserUID: String) {
        let db = Firestore.firestore()
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(followedUserUID).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching followed user data: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("No document found for followed user")
                return
            }

            // Takip isteği gönderildi mi kontrol et
            if let followerRequests = document.get("followerRequests") as? [String], followerRequests.contains(currentUserUID) {
                // Takip isteği gönderildi, butonu güncelle
                self?.updateFollowButtonForRequestSent()
            }
        }
    }




    
    @objc private func followButtonTapped() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let followedUserUsername = username // Takip edilecek kullanıcının username'i

        db.collection("users").whereField("username", isEqualTo: followedUserUsername).getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching followed user's UID: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("No user document found for username: \(followedUserUsername)")
                return
            }

            let followedUserUID = document.documentID

            db.collection("users").document(followedUserUID).getDocument { document, error in
                if let error = error {
                    print("Error checking follow request: \(error.localizedDescription)")
                    return
                }

                guard let document = document, document.exists else { return }

                // Profil gizli mi kontrol et
                if let isPrivate = document.get("isPrivate") as? Bool, isPrivate {
                    // Gizli profil için takip isteği gönder
                    self.sendFollowRequest(followedUserUID: followedUserUID, currentUserUID: currentUserUID)
                } else {
                    // Gizli olmayan profil için direkt takip et
                    self.followUser(followedUserUID: followedUserUID, currentUserUID: currentUserUID)
                }
            }
        }
    }


    
    

    private func sendFollowRequest(followedUserUID: String, currentUserUID: String) {
        let db = Firestore.firestore()

        // İsteği takip edilen kullanıcının `followerRequests` alanına ekle
        db.collection("users").document(followedUserUID).updateData([
            "followerRequests": FieldValue.arrayUnion([currentUserUID])
        ]) { error in
            if let error = error {
                print("Error sending follow request: \(error.localizedDescription)")
            } else {
                print("Follow request successfully added to followerRequests.")
            }
        }

        // İsteği gönderen kullanıcının `followingRequests` alanına ekle
        db.collection("users").document(currentUserUID).updateData([
            "followingRequests": FieldValue.arrayUnion([followedUserUID])
        ]) { [weak self] error in
            if let error = error {
                print("Error updating followingRequests: \(error.localizedDescription)")
            } else {
                print("Follow request successfully added to followingRequests.")
                self?.updateFollowButtonForRequestSent() // Takip isteği gönderildi butonunu güncelle
            }
        }
    }
    
    private func followUser(followedUserUID: String, currentUserUID: String) {
        let db = Firestore.firestore()
        let timestamp = Date() // Bildirimler için zaman damgası

        // Takip eden kullanıcının bilgilerini al
        db.collection("users").document(currentUserUID).getDocument { document, error in
            guard let document = document, document.exists, let userData = document.data() else {
                print("Takip eden kullanıcının bilgileri alınamadı.")
                return
            }

            let followerUsername = userData["username"] as? String ?? "Bilinmeyen Kullanıcı"

            // Takip eden kişinin bilgilerini `followers` alanına ekle
            db.collection("users").document(followedUserUID).updateData([
                "followers": FieldValue.arrayUnion([currentUserUID])
            ]) { error in
                if let error = error {
                    print("Error adding follower: \(error.localizedDescription)")
                    return
                }

                print("User successfully followed.")

                // Hedef kullanıcının notifications koleksiyonuna bildirim ekle
                db.collection("users").document(followedUserUID).collection("notifications").addDocument(data: [
                    "type": "follow",
                    "message": "\(followerUsername) sizi takip etmeye başladı.",
                    "timestamp": timestamp,
                    "followerUID": currentUserUID
                ]) { error in
                    if let error = error {
                        print("Bildirim eklenirken hata oluştu: \(error.localizedDescription)")
                    } else {
                        print("Bildirim başarıyla eklendi.")
                    }
                }
            }

            // Takip eden kişinin `following` alanına güncelleme yap
            db.collection("users").document(currentUserUID).updateData([
                "following": FieldValue.arrayUnion([followedUserUID])
            ]) { [weak self] error in
                if let error = error {
                    print("Error updating following: \(error.localizedDescription)")
                } else {
                    self?.updateFollowButton(isFollowing: true)
                }
            }
        }
    }



    private func cancelFollowRequest(followedUserUID: String, currentUserUID: String) {
        let db = Firestore.firestore()

        db.collection("users").document(followedUserUID).updateData([
            "followingRequests": FieldValue.arrayRemove([currentUserUID])
        ]) { [weak self] error in
            if let error = error {
                print("Error cancelling follow request: \(error.localizedDescription)")
            } else {
                print("Follow request cancelled successfully")
                self?.updateFollowButton(isFollowing: false) // Butonun durumunu "Takip Et" olarak değiştir
            }
        }

        db.collection("users").document(currentUserUID).updateData([
            "followerRequests": FieldValue.arrayRemove([followedUserUID])
        ])
    }




    private func updateFollowButtonForRequestSent() {
        followButton.setTitle("Takip İsteği Gönderildi", for: .normal)
        followButton.backgroundColor = .orange // Buton rengini turuncuya değiştir
    }

    private func updateFollowButton(isFollowing: Bool) {
        if isFollowing {
            followButton.setTitle("Takip Ediliyor", for: .normal)
            followButton.backgroundColor = .gray // Gri renk, takip ediliyorsa
        } else {
            followButton.setTitle("Takip Et", for: .normal)
            followButton.backgroundColor = .blue // Mavi renk, takip etmiyorsanız
        }
    }




    
    
    private func isFollowing(followedUserUID: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = Firestore.firestore()

        // Mevcut kullanıcıyı takip ediyor mu kontrol et
        db.collection("users").document(currentUserUID).getDocument { document, error in
            if let document = document, document.exists {
                if let following = document.get("following") as? [String] {
                    completion(following.contains(followedUserUID))
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }


}


