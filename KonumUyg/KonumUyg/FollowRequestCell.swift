//
//  FollowRequestCell.swift
//  KonumUyg
//
//  Created by reel on 29.11.2024.
//

import UIKit
import Firebase
import FirebaseAuth

protocol FollowRequestCellDelegate: AnyObject {
    func didAcceptRequest(for userUID: String)
    func didDeclineRequest(for userUID: String)
}


class FollowRequestCell: UITableViewCell {
    
    weak var delegate: FollowRequestCellDelegate?

    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let acceptButton = UIButton()
    private let declineButton = UIButton()
    private var userUID: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true

        usernameLabel.translatesAutoresizingMaskIntoConstraints = false

        acceptButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        acceptButton.tintColor = .green
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)

        declineButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        declineButton.tintColor = .red
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [avatarImageView, usernameLabel, acceptButton, declineButton])
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with avatarUrl: String, username: String, userUID: String) {
        avatarImageView.loadImage(from: avatarUrl)
        usernameLabel.text = username
        self.userUID = userUID
    }

    @objc private func acceptTapped() {
            guard let userUID = self.userUID else { return }
            delegate?.didAcceptRequest(for: userUID)
        }

    @objc private func declineTapped() {
            guard let userUID = self.userUID else { return }
            delegate?.didDeclineRequest(for: userUID)
        }


    private func removeCellFromTableView() {
        guard let tableView = superview as? UITableView else { return }
        if let indexPath = tableView.indexPath(for: self) {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }


}
