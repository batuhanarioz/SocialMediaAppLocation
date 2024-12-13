//
//  FollowingController.swift
//  KonumUyg
//
//  Created by reel on 15.11.2024.
//


import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FollowingController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var usernames: [String] = []  // Kullanıcıların UID'lerini burada tutacağız
    private var followingTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUsers()
        setupTableView()
    }

    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.title = "Takip Edilenler"
    }

    // TableView Setup
    private func setupTableView() {
        followingTableView = UITableView()
        followingTableView.translatesAutoresizingMaskIntoConstraints = false
        followingTableView.dataSource = self
        followingTableView.delegate = self
        view.addSubview(followingTableView)

        NSLayoutConstraint.activate([
            followingTableView.topAnchor.constraint(equalTo: view.topAnchor),
            followingTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            followingTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            followingTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followingCell") ?? UITableViewCell(style: .default, reuseIdentifier: "followingCell")
        cell.textLabel?.text = usernames[indexPath.row]
        return cell
    }

    // TableView Delegate (tıklama işlemi)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let username = usernames[indexPath.row]
        let profileVC = ProfileDetailViewController(username: username)
        navigationController?.pushViewController(profileVC, animated: true)
    }

    // Firestore'dan takip edilen kullanıcıları alma
    private func fetchUsers() {
        guard let currentUserUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUserUID).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching following: \(error.localizedDescription)")
                return
            }
            
            if let document = document, let followingArray = document["following"] as? [String] {
                self?.fetchUsernames(for: followingArray)
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
            self.followingTableView.reloadData()
        }
    }
}
