//
//  FollowRequestsViewController.swift
//  KonumUyg
//
//  Created by reel on 29.11.2024.
//


import UIKit
import Firebase
import FirebaseAuth

class FollowRequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var followRequests: [(avatarUrl: String, username: String, userUID: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Takip İstekleri"

        setupTableView()
        fetchFollowRequests()
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FollowRequestCell.self, forCellReuseIdentifier: "FollowRequestCell")
        view.addSubview(tableView)
    }

    private func fetchFollowRequests() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUserUID).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching follow requests: \(error.localizedDescription)")
                return
            }

            guard let document = document, let requests = document.get("followerRequests") as? [String] else {
                print("No follow requests found.")
                return
            }

            let group = DispatchGroup()

            for userUID in requests {
                group.enter()
                db.collection("users").document(userUID).getDocument { snapshot, error in
                    if let error = error {
                        print("Error fetching user details: \(error.localizedDescription)")
                        group.leave()
                        return
                    }

                    if let data = snapshot?.data(),
                       let avatarUrl = data["avatarUrl"] as? String,
                       let username = data["username"] as? String {
                        guard let self = self else { return }
                        self.followRequests.append((avatarUrl, username, userUID))
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self?.tableView.reloadData()
            }
        }
    }

    // TableView Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followRequests.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FollowRequestCell", for: indexPath) as? FollowRequestCell else {
            return UITableViewCell()
        }
        let request = followRequests[indexPath.row]
        cell.configure(with: request.avatarUrl, username: request.username, userUID: request.userUID)
        cell.delegate = self // Burada delegate atanmalı
        return cell
    }


    func handleAcceptButtonTapped(followerUID: String) {
            guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

            acceptFollowRequest(followedUserUID: currentUserUID, followerUID: followerUID)
        }

    func acceptFollowRequest(followedUserUID: String, followerUID: String) {
        let db = Firestore.firestore()

        // Takipçi listesine ekle
        db.collection("users").document(followedUserUID).updateData([
            "followers": FieldValue.arrayUnion([followerUID])
        ]) { error in
            if let error = error {
                print("Takipçi eklenirken hata oluştu: \(error.localizedDescription)")
                return
            }

            print("Takipçi başarıyla eklendi.")

            // Doğru kişiye bildirim gönder
            self.addFollowNotification(toUserUID: followedUserUID, fromUserUID: followerUID)
        }

        // Takip isteğini kaldır
        db.collection("users").document(followedUserUID).updateData([
            "followerRequests": FieldValue.arrayRemove([followerUID])
        ]) { error in
            if let error = error {
                print("Takip isteği kaldırılırken hata oluştu: \(error.localizedDescription)")
            } else {
                print("Takip isteği başarıyla kaldırıldı.")
            }
        }
    }



    private func addFollowNotification(toUserUID followedUserUID: String, fromUserUID followerUID: String) {
        let db = Firestore.firestore()

        // Bildirim için takip eden kişinin bilgilerini getir
        db.collection("users").document(followerUID).getDocument { snapshot, error in
            if let error = error {
                print("Takip eden kullanıcı bilgisi alınamadı: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let followerUsername = data["username"] as? String else {
                print("Takip eden kullanıcı adı bulunamadı.")
                return
            }

            // Doğru mesaj ile bildirim oluştur
            let notificationData: [String: Any] = [
                "message": "\(followerUsername) seni takip etmeye başladı.",
                "timestamp": Timestamp(),
                "followerUID": followerUID
            ]

            // Bildirimi takip edilen kişinin notifications koleksiyonuna ekle
            db.collection("users").document(followedUserUID).collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    print("Bildirim eklenirken hata oluştu: \(error.localizedDescription)")
                } else {
                    print("Bildirim başarıyla eklendi.")
                }
            }
        }
    }







}


extension FollowRequestsViewController: FollowRequestCellDelegate {
    
    func didAcceptRequest(for userUID: String) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let batch = db.batch()

        // Takipçi ekleme
        let currentUserRef = db.collection("users").document(currentUserUID)
        batch.updateData(["followers": FieldValue.arrayUnion([userUID])], forDocument: currentUserRef)

        // Takip isteğini kaldırma
        batch.updateData(["followerRequests": FieldValue.arrayRemove([userUID])], forDocument: currentUserRef)

        batch.commit { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("Takip isteği işlenirken hata: \(error.localizedDescription)")
            } else {
                print("Takip isteği başarıyla kabul edildi.")
                if let index = self.followRequests.firstIndex(where: { $0.userUID == userUID }) {
                    self.followRequests.remove(at: index)
                    self.tableView.performBatchUpdates({
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    }, completion: nil)
                }
            }
        }
    }


        func didDeclineRequest(for userUID: String) {
            guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUserUID).updateData([
            "followerRequests": FieldValue.arrayRemove([userUID])
        ]) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("Error removing follow request: \(error.localizedDescription)")
                return
            }

            if let index = self.followRequests.firstIndex(where: { $0.userUID == userUID }) {
                self.followRequests.remove(at: index)
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                }, completion: nil)
            }
        }
    }
}
