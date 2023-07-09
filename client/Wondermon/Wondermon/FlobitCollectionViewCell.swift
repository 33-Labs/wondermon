//
//  FlobitCollectionViewCell.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import UIKit

class FlobitCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "FlobitCollectionViewCell"
    let imageView = UIImageView()
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .brown

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
//    private func setupLabel() {
//        label.textAlignment = .center
//
//        contentView.addSubview(label)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            label.heightAnchor.constraint(equalToConstant: 20)
//        ])
//    }
}

