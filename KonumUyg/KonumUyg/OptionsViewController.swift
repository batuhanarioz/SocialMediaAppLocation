//
//  OptionsViewController.swift
//  KonumUyg
//
//  Created by reel on 28.11.2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class OptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    private var notifications: [[String: Any]] = []
    let titleLabel = UILabel()  // Bildirimler başlığı için bir label

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadNotifications()  // Bildirimleri yükle
    }

    private func setupUI() {
        view.backgroundColor = .white
        
        // Takip İstekleri Butonu
        let followRequestButton = UIButton()
        followRequestButton.setTitle("Takip İstekleri", for: .normal)
        followRequestButton.backgroundColor = .blue
        followRequestButton.translatesAutoresizingMaskIntoConstraints = false
        followRequestButton.addTarget(self, action: #selector(followRequestTapped), for: .touchUpInside)
        view.addSubview(followRequestButton)
        
        // Bildirimler Başlığı
        titleLabel.text = "Bildirimler"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Bildirimler TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        view.addSubview(tableView)
        
        // Çıkış Yap Butonu
        let logoutButton = UIButton()
        logoutButton.setTitle("Çıkış Yap", for: .normal)
        logoutButton.backgroundColor = .red
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        view.addSubview(logoutButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            followRequestButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            followRequestButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            followRequestButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            followRequestButton.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: followRequestButton.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: logoutButton.topAnchor, constant: -20),
            
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadNotifications() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUserUID).collection("notifications")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Bildirimler alınırken hata: \(error.localizedDescription)")
                    return
                }

                self?.notifications = snapshot?.documents.compactMap { $0.data() } ?? []
                self?.tableView.beginUpdates()
                // Eklediğiniz veya silinen satırları burada güncelleyin.
                self?.tableView.endUpdates()
            }
    }



    // Takip İstekleri Butonu Tıklama
    @objc private func followRequestTapped() {
        let followRequestsVC = FollowRequestsViewController()
        navigationController?.pushViewController(followRequestsVC, animated: true)
    }

    @objc private func logoutTapped() {
        // Firebase Authentication ile çıkış yap
        do {
            try Auth.auth().signOut()
            print("Çıkış başarılı")

            // LoginViewController'a geçiş
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true, completion: nil)
        } catch {
            print("Çıkış yaparken hata oluştu: \(error.localizedDescription)")
        }
    }

    // TableView Veri Kaynağı
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath)

        let notification = notifications[indexPath.row]
        cell.textLabel?.text = notification["message"] as? String
        if let timestamp = notification["timestamp"] as? Timestamp {
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: timestamp.dateValue(), dateStyle: .medium, timeStyle: .short)
        }

        return cell
    }



}
