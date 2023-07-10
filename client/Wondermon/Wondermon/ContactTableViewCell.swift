//
//  ContactTableViewCell.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/10.
//

import UIKit

class ContactTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ContactCell"
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .wm_deepPurple
        return label
    }()
    
    let addressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(nameLabel)
        addSubview(addressLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            
            addressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            addressLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
