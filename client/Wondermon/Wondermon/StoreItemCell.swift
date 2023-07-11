//
//  FlobitStoreCell.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/11.
//

import UIKit
import Kingfisher

class StoreItemCell: UICollectionViewCell {
    static let reuseIdentifier = "StoreItemCell"
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var priceLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 20)
        view.textAlignment = .center
        view.textColor = .wm_deepPurple
        return view
    }()
    
    private lazy var idLabel: UILabel = {
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
    
    func setFlovatar(_ flovatar: Flovatar) {
        let rawUrl = flovatar.display.thumbnail.url.replacingOccurrences(of: "svg", with: "png")
        let url = URL(string: rawUrl)
        imageView.kf.setImage(with: url)
        priceLabel.text = "$60"
        idLabel.text = ""
    }
    
    func setFlobit(_ flobit: Flobit) {
        let url = URL(string: flobit.display.thumbnail.url)
        imageView.kf.setImage(with: url, options: [.processor(SVGImgProcessor())])
        priceLabel.text = "$10"
        idLabel.text = ""
    }
    
    func setToken(_ token: Token) {
        imageView.image = token.logo
        idLabel.text = ""
        priceLabel.text = "$200"
    }

    private func setupUI() {
        contentView.backgroundColor = .wm_purple
        contentView.layer.cornerRadius = 30
        contentView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, constant: -6).isActive = true
        
        contentView.addSubview(idLabel)
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        idLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        idLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        idLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        idLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -2).isActive = true
        
        contentView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        priceLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        priceLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
    }
}

