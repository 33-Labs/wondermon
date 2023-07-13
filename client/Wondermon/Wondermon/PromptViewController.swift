//
//  PromptViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/13.
//

import UIKit
import Flow
import NotificationBannerSwift
import SafariServices
import NotificationBannerSwift

class PromptViewController: UIViewController {
    
    fileprivate var user: User?

    lazy var textView: UITextView = {
        let view = UITextView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.wm_deepPurple.cgColor
        view.font = .systemFont(ofSize: 16)
        view.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return view
    }()
    
    lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "prompt")

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(resetButton)
        
        resetButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        resetButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        return view
    }()
    
    lazy var resetButton: UIButton = {
        let view = UIButton()
        view.imageView?.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "reset"), for: .normal)
        view.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return view
    }()
    
    lazy var submitButton: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "submit"), for: .normal)
        view.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        return view
    }()
    
    let flovatarId: UInt64
    
    init(flovatarId: UInt64) {
        self.flovatarId = flovatarId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupUI()
        getUser()
        loadPromptTemplate()
    }
    
    private func setupUI() {
        view.addSubview(headerView)
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        textView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        textView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        
        view.addSubview(submitButton)
        submitButton.leadingAnchor.constraint(equalTo: textView.leadingAnchor).isActive = true
        submitButton.trailingAnchor.constraint(equalTo: textView.trailingAnchor).isActive = true
        submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    private func getUser() {
        self.user = UserDefaults.standard.fetchUser()
    }
    
    private func loadPromptTemplate() {
        Task { [weak self] in
            guard let sSelf = self else { return }
            do {
                let template = try await sSelf.fetchPromptTemplate()
                DispatchQueue.main.async { [weak self] in
                    self?.textView.text = template
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func fetchPromptTemplate() async throws -> String {
        guard let user = user,
              let _ = user.flowAccount else {
            return ""
        }
        
        let rawScript = fetchPromptTemplateScript()
        let script = Flow.Script(text: rawScript)
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [.init(value: .uint64(flovatarId))])
        let b64Template: String = try result.decode()
        if let decodedData = Data(base64Encoded: b64Template),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            return decodedString
        }
        return ""
    }
    
    private func fetchPromptTemplateScript() -> String {
        return """
import WondermonFlovatarPromptTemplate from 0x504dadc2410ae4f6

pub fun main(flovatarId: UInt64): String {
    return WondermonFlovatarPromptTemplate.getPromptTemplate(flovatarId: flovatarId)
}
"""
    }
    
    @objc func resetButtonTapped(_ sender: UIButton) {
        NetworkManager.shared.removePromptTemplate(flovatarId: flovatarId) { [weak self] result in
            Task {
                switch result {
                case .success(let txid):
                    await self?.watchTransaction(transactionHash: txid.txid, onSuccess: {
                        self?.loadPromptTemplate()
                    })
                case .failure(let error):
                    print(error)
                    let banner = FloatingNotificationBanner(title: "Operation failed", style: .warning)
                    banner.duration = 1
                    banner.show()
                }
            }
        }
    }
    
    @objc func submitButtonTapped(_ sender: UIButton) {
        guard textView.text.count > 0 else {
            return
        }
        
        NetworkManager.shared.setPromptTemplate(flovatarId: flovatarId, template: textView.text) { [weak self] result in
            Task {
                switch result {
                case .success(let txid):
                    await self?.watchTransaction(transactionHash: txid.txid, onSuccess: {
                        self?.loadPromptTemplate()
                    })
                case .failure(let error):
                    print(error)
                    let banner = FloatingNotificationBanner(title: "Operation failed", style: .warning)
                    banner.duration = 1
                    banner.show()
                }
            }
        }
    }
    
    private func watchTransaction(transactionHash: String, onSuccess: (() -> Void)? = nil, onFailure: (() -> Void)? = nil) async {
        let txid = Flow.ID(hex: transactionHash)
        do {
            let banner = FloatingNotificationBanner(title: "Transaction pending, tap to view", style: .info)
            banner.onTap = { [weak self] in
                self?.navigateToTransaction(txid: transactionHash)
            }
            
            banner.duration = 5
            banner.show()
            
            let result = try await txid.onceSealed()
            if result.status == .sealed && result.errorMessage == "" {
                let banner = FloatingNotificationBanner(title: "Transaction sealed, tap to view", style: .success)
                banner.onTap = { [weak self] in
                    self?.navigateToTransaction(txid: transactionHash)
                }
                banner.duration = 2
                banner.show()
                onSuccess?()
            } else {
                let banner = FloatingNotificationBanner(title: "Transaction failed, tap to view", style: .warning)
                banner.onTap = { [weak self] in
                    self?.navigateToTransaction(txid: transactionHash)
                }
                banner.duration = 2
                banner.show()
                onFailure?()
            }
        } catch {
            debugPrint("Transaction failed \(error)")
            let banner = FloatingNotificationBanner(title: "Transaction failed, tap to view", style: .warning)
            banner.onTap = { [weak self] in
                self?.navigateToTransaction(txid: transactionHash)
            }
            banner.duration = 2
            banner.show()
            onFailure?()
        }
    }
    
    func navigateToTransaction(txid: String) {
        guard let url = URL(string: "https://flowscan.org/transaction/\(txid)") else {
            return
        }
        
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .overFullScreen
        present(safariViewController, animated: true, completion: nil)
    }
}
