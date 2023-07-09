//
//  FlobitsHeaderView.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import UIKit

class FlobitsHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "FlobitsHeader"
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "flobits")

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
