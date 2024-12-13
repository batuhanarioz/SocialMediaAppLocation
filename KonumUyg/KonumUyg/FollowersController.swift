//
//  FollowersViewController.swift
//  KonumUyg
//
//  Created by reel on 15.11.2024.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FollowersController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var usernames: [String] = []  // Kullanıcıların UID'lerini burada tutacağız
    private var followersTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUsers()
        setupTableView()
    }

    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.title = "Takipçiler"
    }

    // TableView Setup
    private func setupTableView() {
        followersTableView = UITableView()
        followersTableView.translatesAutoresizingMaskIntoConstraints = false
        followersTableView.dataSource = self
        followersTableView.delegate = self
        view.addSubview(followersTableView)

        NSLayoutConstraint.activate([
            followersTableView.topAnchor.constraint(equalTo: view.topAnchor),
            followersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            followersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            followersTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followerCell") ?? UITableViewCell(style: .default, reuseIdentifier: "followerCell")
        cell.textLabel?.text = usernames[indexPath.row]
        return cell
    }

    // TableView Delegate (tıklama işlemi)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let username = usernames[indexPath.row]
        let profileVC = ProfileDetailViewController(username: username)
        navigationController?.pushViewController(profileVC, animated: true)
    }

    // Firestore'dan takipçileri alma
    private func fetchUsers() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUserUID).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching followers: \(error.localizedDescription)")
                return
            }

            if let document = document, let followersArray = document["followers"] as? [String] {
                self?.fetchUsernames(for: followersArray)
            }
        }
    }
    
    // UserUID'leri kullanarak username'leri çekme
        private func fetchUsernames(for userUIDs: [String]) {
            let db = Firestore.firestore()
            let dispatchGroup = DispatchGroup()

            var fetchedUsernames: [String] = []

            for userUID in userUIDs {
                dispatchGroup.enter()
                db.collection("users").document(userUID).getDocument { document, error in
                    if let document = document, let username = document["username"] as? String {
                        fetchedUsernames.append(username)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.usernames = fetchedUsernames
                self.followersTableView.reloadData()
            }
        }
}
