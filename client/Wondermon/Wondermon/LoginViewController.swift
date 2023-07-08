//
//  ViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit

class LoginViewController: UIViewController {
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .green
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()
    
    private lazy var usernameField: UITextField = {
        let view = UITextField()
        view.placeholder = "Username"
        view.borderStyle = .roundedRect
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var passwordField: UITextField = {
        let view = UITextField()
        view.placeholder = "Password"
        view.isSecureTextEntry = true
        view.borderStyle = .roundedRect
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var loginButton: UIButton = {
       let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .green
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private lazy var signUpLabel: UILabel = {
        let signUpText = "Don't have an account? SIGN UP now!"
        let signUpLinkText = "SIGN UP"
        
        let attributedString = NSMutableAttributedString(string: signUpText)
        let range = (signUpText as NSString).range(of: signUpLinkText)
        
        attributedString.addAttribute(.foregroundColor, value: UIColor.blue, range: range)
        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: range)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(signUpTapped(_:)))
        
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attributedString
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGesture)
        
        return label
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .brown
        setupGestures()
        setupUI()
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 220).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(usernameField)
        usernameField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        usernameField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        usernameField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        usernameField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 50).isActive = true
        
        view.addSubview(passwordField)
        passwordField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 30).isActive = true
        
        view.addSubview(loginButton)
        loginButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 30).isActive = true
        
        view.addSubview(signUpLabel)
        signUpLabel.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        signUpLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signUpLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 50).isActive = true
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func signUpTapped(_ gesture: UITapGestureRecognizer) {
        // 处理 SIGN UP 被点击的逻辑，例如跳转到注册页面
        print("SIGN UP tapped!")
    }
}

