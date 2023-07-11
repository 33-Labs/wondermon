//
//  StoreCollectionHeaderView.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/11.
//

import UIKit

class StoreCollectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "StoreCollectionHeaderView"
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupImageView() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.widthAnchor.constraint(equalToConstant: 150),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

