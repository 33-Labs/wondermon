//
//  TokenViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/10.
//

import UIKit

struct Token {
    let symbol: String
    let logo: UIImage
}

class TokenView: UIView {
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = .boldSystemFont(ofSize: 16)
        return view
    }()
    
    private lazy var balanceLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .right
        view.font = .boldSystemFont(ofSize: 16)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setToken(_ token: Token) {
        iconView.image = token.logo
        nameLabel.text = token.symbol
    }
    
    func setBalance(_ balance: Decimal) {
        balanceLabel.text = "\(balance)"
    }
    
    private func setupUI() {
        addSubview(iconView)
        iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor).isActive = true
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        
        addSubview(nameLabel)
        nameLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: iconView.heightAnchor).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8).isActive = true
        
        addSubview(balanceLabel)
        balanceLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor).isActive = true
        balanceLabel.heightAnchor.constraint(equalTo: nameLabel.heightAnchor).isActive = true
        balanceLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        balanceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    }
    
}
