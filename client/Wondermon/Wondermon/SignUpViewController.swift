//
//  ViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit

class SignUpViewController: UIViewController {
    
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
    
    private lazy var repeatPasswordField: UITextField = {
        let view = UITextField()
        view.placeholder = "Confirm Password"
        view.isSecureTextEntry = true
        view.borderStyle = .roundedRect
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var signUpButton: UIButton = {
       let button = UIButton()
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = .green
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
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
        
        view.addSubview(repeatPasswordField)
        repeatPasswordField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        repeatPasswordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        repeatPasswordField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        repeatPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 30).isActive = true
        
        view.addSubview(signUpButton)
        signUpButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        signUpButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpButton.topAnchor.constraint(equalTo: repeatPasswordField.bottomAnchor, constant: 30).isActive = true
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

