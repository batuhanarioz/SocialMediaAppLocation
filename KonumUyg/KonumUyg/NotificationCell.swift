//
//  NotificationCell.swift
//  KonumUyg
//
//  Created by reel on 30.11.2024.
//

import UIKit
import FirebaseCore

class NotificationCell: UITableViewCell {
    var messageLabel: UILabel!
    var timestampLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        messageLabel = UILabel()
        timestampLabel = UILabel()

        contentView.addSubview(messageLabel)
        contentView.addSubview(timestampLabel)

        // Layout kodlarını buraya ekleyin (AutoLayout kullanarak)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with notification: [String: Any]) {
        messageLabel.text = notification["message"] as? String
        if let timestamp = notification["timestamp"] as? Timestamp {
            timestampLabel.text = DateFormatter.localizedString(from: timestamp.dateValue(), dateStyle: .medium, timeStyle: .short)
        }
    }
}
