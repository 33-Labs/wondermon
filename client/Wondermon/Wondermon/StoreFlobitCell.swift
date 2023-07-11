//
//  FlobitStoreCell.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/11.
//

import UIKit
import Kingfisher

class StoreFlobitCell: UICollectionViewCell {
    static let reuseIdentifier = "StoreFlobitCell"
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        view.backgroundColor = .wm_purple
        return view
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setFlobit(_ flobit: Flobit) {
        label.text = "#\(flobit.id)"
    }

    private func setupUI() {
        contentView.backgroundColor = .green
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -5).isActive = true
    }
}

