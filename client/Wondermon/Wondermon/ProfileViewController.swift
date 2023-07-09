//
//  ProfileViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import UIKit

class ProfileViewController: UIViewController {
    
    private var user: User? {
        didSet {
            if let user = user {
                nameLabel.text = user.name
                emailLabel.text = user.email
                if let flowAccount = user.flowAccount {
                    addressLabel.text = flowAccount.address
                }
            } else {
                nameLabel.text = nil
                emailLabel.text = nil
                addressLabel.text = nil
            }
        }
    }
    
    private lazy var signOutButton: UIButton = {
       let button = UIButton()
        button.setImage(UIImage(named: "signout"), for: .normal)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profile")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        return view
    }()
    
    private lazy var profileView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(nameView)
        nameView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        nameView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        nameView.topAnchor.constraint(equalTo: view.topAnchor, constant: 1).isActive = true
        nameView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        view.addSubview(emailView)
        emailView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        emailView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        emailView.topAnchor.constraint(equalTo: nameView.bottomAnchor).isActive = true
        emailView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        view.addSubview(addressView)
        addressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        addressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        addressView.topAnchor.constraint(equalTo: emailView.bottomAnchor).isActive = true
        addressView.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let view = UILabel()
        view.textColor = .black
        view.font = .systemFont(ofSize: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var nameView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        view.addSubview(title)
        title.text = "NAME"
        title.textColor = .wm_deepPurple
        title.font = .systemFont(ofSize: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        title.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        title.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        view.addSubview(nameLabel)
        nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        nameLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor).isActive = true
        nameLabel.textAlignment = .right
        
        let topLine = UIView()
        view.addSubview(topLine)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        topLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        topLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        topLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        topLine.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topLine.backgroundColor = .wm_purple
        
        return view
    }()
    
    private lazy var emailLabel: UILabel = {
        let view = UILabel()
        view.textColor = .black
        view.font = .systemFont(ofSize: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var emailView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        view.addSubview(title)
        title.text = "EMAIL"
        title.textColor = .wm_deepPurple
        title.font = .systemFont(ofSize: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        title.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        title.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        view.addSubview(emailLabel)
        emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        emailLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        emailLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        emailLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor).isActive = true
        emailLabel.textAlignment = .right
        
        let topLine = UIView()
        view.addSubview(topLine)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        topLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        topLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        topLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        topLine.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topLine.backgroundColor = .wm_purple
        
        return view
    }()
    
    private lazy var addressLabel: UILabel = {
        let view = UILabel()
        view.textColor = .black
        view.font = .systemFont(ofSize: 16)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var addressView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let title = UILabel()
        view.addSubview(title)
        title.text = "ADDRESS"
        title.textColor = .wm_deepPurple
        title.font = .systemFont(ofSize: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        title.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        title.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        view.addSubview(addressLabel)
        addressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        addressLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        addressLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        addressLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor).isActive = true
        addressLabel.textAlignment = .right
        
        let topLine = UIView()
        view.addSubview(topLine)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        topLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        topLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        topLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        topLine.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topLine.backgroundColor = .wm_purple
        
        let bottomLine = UIView()
        view.addSubview(bottomLine)
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        bottomLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        bottomLine.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1).isActive = true
        bottomLine.backgroundColor = .wm_purple
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        getUser()
        setupUI()
        
//        setupNavigationBar()
//        setupUI()
//        setupAudio()
//
//        fetchFlovatarData()
    }
    
    private func setupUI() {
        view.addSubview(headerView)
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        view.addSubview(profileView)
        profileView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 48).isActive = true
        profileView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        profileView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        profileView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        view.addSubview(signOutButton)
        signOutButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOutButton.topAnchor.constraint(equalTo: profileView.bottomAnchor, constant: 60).isActive = true
    }
    
    private func getUser() {
        if let user = UserDefaults.standard.fetchUser() {
            self.user = user
        }
    }
    
    @objc private func signOutTapped(_ sender: UIButton) {
        UserDefaults.standard.deleteUser()
        user = nil
        dismiss(animated: true)
    }
}
