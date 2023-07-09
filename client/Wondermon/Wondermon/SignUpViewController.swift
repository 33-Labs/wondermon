//
//  ViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit
import NotificationBannerSwift

class SignUpViewController: UIViewController {
    
    private lazy var titleView: UIView = {
       let view = UIView()
        view.backgroundColor = .wm_purple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = UIImage(named: "logo")
        return view
    }()
    
    private lazy var emailBorder: CALayer = {
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor.wm_deepPurple.cgColor
        return bottomBorder
    }()
    
    private lazy var passwordBorder: CALayer = {
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor.wm_deepPurple.cgColor
        return bottomBorder
    }()
    
    private lazy var repeatPasswordBorder: CALayer = {
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor.wm_deepPurple.cgColor
        return bottomBorder
    }()
    
    private lazy var emailField: UITextField = {
        let view = UITextField()
        view.placeholder = "Email"
        view.backgroundColor = .clear
        view.borderStyle = .none
        view.keyboardType = .emailAddress
        view.layer.addSublayer(emailBorder)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    private lazy var passwordField: UITextField = {
        let view = UITextField()
        view.placeholder = "Password"
        view.isSecureTextEntry = true
        view.backgroundColor = .clear
        view.borderStyle = .none
        view.layer.addSublayer(passwordBorder)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        
        return view
    }()
    
    private lazy var repeatPasswordField: UITextField = {
        let view = UITextField()
        view.placeholder = "Confirm Password"
        view.isSecureTextEntry = true
        view.backgroundColor = .clear
        view.borderStyle = .none
        view.layer.addSublayer(repeatPasswordBorder)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        
        return view
    }()
    
    private lazy var signUpButton: UIButton = {
       let button = UIButton()
        button.setImage(UIImage(named: "signup"), for: .normal)
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var signInLabel: UILabel = {
        let signInText = "Already registered? SIGN IN now!"
        let signInLinkText = "SIGN IN"
        
        let attributedString = NSMutableAttributedString(string: signInText)
        let range = (signInText as NSString).range(of: signInLinkText)
        
        attributedString.addAttribute(.foregroundColor, value: UIColor.wm_deepPurple, range: range)
        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: range)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(signInTapped(_:)))
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = attributedString
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGesture)
        
        return label
    }()
    
    fileprivate var activeTextField: UITextField?
    fileprivate var activeButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupGestures()
        setupNotifications()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        emailBorder.frame = CGRect(x: 0, y: emailField.frame.height - 1, width: emailField.frame.width, height: 1)
        passwordBorder.frame = CGRect(x: 0, y: passwordField.frame.height - 1, width: passwordField.frame.width, height: 1)
        repeatPasswordBorder.frame = CGRect(x: 0, y: repeatPasswordField.frame.height - 1, width: repeatPasswordField.frame.width, height: 1)
        
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.addSubview(titleView)
        titleView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        titleView.heightAnchor.constraint(equalTo: titleView.widthAnchor).isActive = true
        titleView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        titleView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        titleView.addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 230).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor, constant: 50).isActive = true
        
        view.addSubview(emailField)
        emailField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        emailField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        emailField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emailField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 50).isActive = true
        
        view.addSubview(passwordField)
        passwordField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16).isActive = true
        
        view.addSubview(repeatPasswordField)
        repeatPasswordField.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        repeatPasswordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        repeatPasswordField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        repeatPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16).isActive = true
        
        view.addSubview(signUpButton)
        signUpButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        signUpButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpButton.topAnchor.constraint(equalTo: repeatPasswordField.bottomAnchor, constant: 50).isActive = true
        
        view.addSubview(signInLabel)
        signInLabel.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        signInLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInLabel.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 50).isActive = true
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func signInTapped(_ gesture: UITapGestureRecognizer) {
        print("SIGN IN tapped!")
        self.dismiss(animated: true)
    }
    
    @objc func signUpTapped(_ sender: UIButton) {
        print("SIGN UP TAPPED")
        if let email = emailField.text,
            email.isValidEmail() {
            dismissAllViewControllers()
        } else {
            let banner = FloatingNotificationBanner(title: "Invalid Email", style: .warning)
            banner.duration = 1
            banner.show()
        }

    }
    
    func dismissAllViewControllers() {
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let activeTextField = activeTextField else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        let extraDistance: CGFloat = 10

        let textFieldOrigin = activeTextField.convert(activeTextField.bounds, to: view).origin.y
        let overlap = textFieldOrigin + activeTextField.frame.size.height - (view.bounds.height - keyboardHeight - extraDistance)

        if overlap > 0 {
            animateViewMoving(up: true, distance: overlap)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        animateViewMoving(up: false, distance: 0)
    }
    
    private func animateViewMoving(up: Bool, distance: CGFloat) {
        let movementDuration: TimeInterval = 0.3

        let movement = up ? -distance : 0

        UIView.animate(withDuration: movementDuration,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: { [weak self] in
                           self?.view.frame.origin.y = movement
                       },
                       completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}
