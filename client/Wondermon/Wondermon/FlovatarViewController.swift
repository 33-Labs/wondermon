//
//  FlovatarViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit
import Flow
//import Macaw
import Speech
import AVFoundation
import MicrosoftCognitiveServicesSpeech
import WebKit
import NotificationBannerSwift
import SafariServices

class FlovatarViewController: UIViewController, UINavigationBarDelegate, SFSpeechRecognizerDelegate {
    
    private var user: User? {
        didSet {
            fetchFlovatarData()
        }
    }
    
    private var flovatarId: UInt64? {
        didSet {
            if let _ = flovatarId {
                unauthenticatedCoverView.isHidden = true
            } else {
                unauthenticatedCoverView.isHidden = false
            }
        }
    }
    
    private var convertedText: String? {
        didSet {
            if let user = user,
               let convertedText = convertedText,
               let flovatarId = flovatarId{
                speakView.text = "\(user.name): \(convertedText)\n"
                chat(prompt: convertedText, flovatarId: flovatarId)
            } else {
                speakView.text = ""
            }
            
        }
    }
    
    private lazy var speakView: UITextView = {
        let view = UITextView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.wm_deepPurple.cgColor
        view.isEditable = false
        view.font = .systemFont(ofSize: 16)
        view.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight)
        )
        return view
    }()
    
    private lazy var webView: WKWebView = {
        let view = WKWebView()
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = false
        
        let pagePrefs : WKWebpagePreferences = {
            let prefs = WKWebpagePreferences()
            prefs.preferredContentMode = .mobile
            prefs.allowsContentJavaScript = false
            return prefs
        }()
        
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.allowsAirPlayForMediaPlayback = false
        config.defaultWebpagePreferences = pagePrefs
        
        view.scrollView.isScrollEnabled = false
        view.scrollView.backgroundColor = .green
        view.backgroundColor = .yellow
        view.scrollView.showsVerticalScrollIndicator = false
        view.scrollView.showsHorizontalScrollIndicator = false
        
        return view
    }()
    
    private lazy var flobitsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "flobits"), for: .normal)
        button.addTarget(self, action: #selector(flobitsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var tokensButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "tokens"), for: .normal)
        button.addTarget(self, action: #selector(tokensButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var contactsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "contacts"), for: .normal)
        button.addTarget(self, action: #selector(contactsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var storeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "store"), for: .normal)
        button.addTarget(self, action: #selector(storeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var unauthenticatedCoverView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.tintColor = .wm_purple
        imageView.image = UIImage(named: "flovatar")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
        
        return view
    }()
    
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private lazy var speechRecognizer: SFSpeechRecognizer = {
        let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        speechRecognizer.delegate = self
        return speechRecognizer
    }()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private lazy var audioButton: UIButton = {
        let button = UIButton()
        let startImage = UIImage(named: "holdtotalk")
        let stopImage = UIImage(named: "releasetosend")
        button.setImage(startImage, for: .normal)
        button.setImage(stopImage, for: .focused)
        button.setImage(stopImage, for: .highlighted)
        button.setImage(stopImage, for: .disabled)
        
        button.addTarget(self, action: #selector(audioButtonTapped), for: .touchDown)
        button.addTarget(self, action: #selector(audioButtonTapped), for: .touchUpInside)
        button.addTarget(self, action: #selector(audioButtonTapped), for: .touchUpOutside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.deleteMessages()
        UserDefaults.standard.addObserver(self, forKeyPath: "user", options: .new, context: nil)
        
        getUser()
        
        view.backgroundColor = .wm_purple
        setupNavigationBar()
        setupUI()
        setupAudio()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "user" {
            getUser()
        }
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .wm_deepPurple
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.titleView = {
            let view = UIImageView()
            view.image = UIImage(named: "slogan")
            return view
        }()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "user"), style: .plain, target: self, action: #selector(profileButtonTapped))
    }
    
    private func setupAudio() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.audioButton.isEnabled = true
                } else {
                    self.audioButton.isEnabled = false
                }
            }
        }
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        } catch {
            print("setup audioSession failed")
        }
    }
    
    private func getUser() {
        self.user = UserDefaults.standard.fetchUser()
    }
    
    private func fetchFlovatarData(completion: (() -> Void)? = nil)  {
        guard let user = user,
              let flowAccount = user.flowAccount else {
            cleanFlovatar()
            return
        }

        Task {
            do {
                let rawAddress = flowAccount.address
                let tokenIds = try await self.fetchFlovatarIds(rawAddress: rawAddress)
                if (tokenIds.count > 0) {
                    let tokenId = tokenIds[0]
                    flovatarId = tokenId
                    let svg = try await self.fetchFlovatarSvg(rawAddress: rawAddress, flovatarId: tokenId)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let sSelf = self else { return }
                        sSelf.webView.loadHTMLString("<div style=\"width: 100%; height: 100%;\">\(svg)</div>", baseURL: nil)
                        completion?()
                    }
                } else {
                    cleanFlovatar()
                }
            } catch {
                cleanFlovatar()
            }
        }
    }
    
    private func cleanFlovatar() {
        flovatarId = nil
    }
    
    private func setupUI() {
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        contentView.heightAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72).isActive = true
        contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        contentView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: 8).isActive = true
        webView.heightAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
        webView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72).isActive = true
        webView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        contentView.addSubview(unauthenticatedCoverView)
        unauthenticatedCoverView.translatesAutoresizingMaskIntoConstraints = false
        unauthenticatedCoverView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        unauthenticatedCoverView.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        unauthenticatedCoverView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        unauthenticatedCoverView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        contentView.addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        blurView.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        blurView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        blurView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        blurView.alpha = 0
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 5).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.addArrangedSubview(flobitsButton)
        stackView.addArrangedSubview(tokensButton)
        stackView.addArrangedSubview(contactsButton)
        stackView.addArrangedSubview(storeButton)
        
        view.addSubview(audioButton)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButton.widthAnchor.constraint(equalToConstant:  280).isActive = true
        audioButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        audioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        audioButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40).isActive = true
        
        view.addSubview(speakView)
        speakView.translatesAutoresizingMaskIntoConstraints = false
        speakView.topAnchor.constraint(equalTo: flobitsButton.bottomAnchor, constant: 16).isActive = true
        speakView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        speakView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        speakView.bottomAnchor.constraint(equalTo: audioButton.topAnchor, constant: -16).isActive = true
    }
    
    private func fetchFlovatarSvg(rawAddress: String, flovatarId: UInt64) async throws -> String {
        let rawScript = fetchFlovatarSvgScript()
        let script = Flow.Script(text: rawScript)
        let address = Flow.Address(hex: rawAddress)
        
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [
            .init(value: .address(address)),
            .init(value: .uint64(flovatarId))
        ])
        let svg: String = try result.decode()
        return svg
        
    }
    
    private func fetchFlovatarIds(rawAddress: String) async throws -> [UInt64] {
        let rawScript = fetchFlovatarIdsScript()
        let script = Flow.Script(text: rawScript)
        let address = Flow.Address(hex: rawAddress)
        
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [.init(value: .address(address))])
        let tokenIds: [UInt64] = try result.decode()
        return tokenIds
    }
    
    private func fetchFlovatarIdsScript() -> String {
        return """
        import Flovatar from 0x921ea449dffec68a

        pub fun main(address: Address): [UInt64] {
            let account = getAccount(address)
            let collection = account.getCapability(Flovatar.CollectionPublicPath).borrow<&{Flovatar.CollectionPublic}>()
                ?? panic("Could not borrow Flovatar collection")
            return collection.getIDs()
        }
        """
    }
    
    private func fetchFlovatarSvgScript() -> String {
        return """
        import Flovatar from 0x921ea449dffec68a

        pub fun main(address: Address, flovatarId: UInt64): String {
          let account = getAuthAccount(address)

          let flovatarCap = account
            .getCapability(Flovatar.CollectionPublicPath)
            .borrow<&{Flovatar.CollectionPublic}>()
            ?? panic("Could not borrow flovatar public collection")

          let flovatar = flovatarCap.borrowFlovatar(id: flovatarId)
            ?? panic("Could not borrow flovatar with that ID from collection")

          return flovatar.getSvg()
        }
        """
    }
    
    @objc func audioButtonTapped(_ sender: UIButton) {
        if let _ = user {
            if audioEngine.isRunning {
                stopRecording()
            } else {
                startRecording()
            }
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    private func startRecording() {
        audioButton.isEnabled = false
        convertedText = nil
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        do {
            try audioSession.setActive(true)
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
                guard let sSelf = self else { return }
                
                var finished = false
                if let result = result {
                    let recognizedText = result.bestTranscription.formattedString
                    if result.isFinal {
                        sSelf.convertedText = recognizedText
                        finished = true
                    }
                }
                
                if let error = error {
                    debugPrint("Recognition error: \(error)")
                }
                
                if error != nil || finished {
                    sSelf.resetRecordingStatus()
                }
            })
            
            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
                recognitionRequest.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            resetRecordingStatus()
            print("Audio engine error: \(error)")
        }
    }
    
    private func stopRecording() {
        resetRecordingStatus()
    }
    
    private func resetRecordingStatus() {
        try? audioSession.setActive(false)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest = nil
        recognitionTask = nil

        audioButton.isEnabled = true
    }
    
    @objc func flobitsButtonTapped(_ sender: UIButton) {
        if let _ = user {
            let vc = FlobitsCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func tokensButtonTapped(_ sender: UIButton) {
        if let _ = user {
            let vc = TokensViewController()
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func contactsButtonTapped(_ sender: UIButton) {
        if let _ = user {
            let vc = ContactViewController()
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func storeButtonTapped(_ sender: UIButton) {
        if let _ = user {
            let vc = StoreViewController()
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func profileButtonTapped(_ sender: UIBarButtonItem) {
        if let _ = user {
            let vc = ProfileViewController()
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    private func chat(prompt: String, flovatarId: UInt64) {
        let messages = UserDefaults.standard.fetchMessages()
        NetworkManager.shared.chat(prompt: prompt, flovatarId: flovatarId, messages: messages) { [weak self] result in
            guard let sSelf = self else { return }
            switch result {
            case .success(let message):
                let humanMessage = Message(name: "human", text: prompt)
                let aiMessage = Message(name: "ai", text: message.message)
                
                if UserDefaults.standard.store(message: humanMessage) &&
                    UserDefaults.standard.store(message: aiMessage) {
                    sSelf.speakView.text = "Flora: \(message.message)"
                    DispatchQueue.global().async { [weak self] in
                        self?.speak(text: message.message)
                    }
                } else {
                    // TODO: Alert persist error
                }
                
                DispatchQueue.main.async { [weak self] in
                    Task {
                        if let txid = message.txid {
                            await self?.handleTxid(txid)
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
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
    
    private func handleTxid(_ txid: String) async {
        func fadeBlurView() {
            UIView.animate(withDuration: 2, animations: { [weak self] in
                self?.blurView.alpha = 0
            })
        }
        
        let tx = txid
        
        let banner = FloatingNotificationBanner(title: "Transaction pending, tap to view", style: .info)
        banner.onTap = { [weak self] in
            self?.navigateToTransaction(txid: tx)
        }
        
        banner.duration = 5
        banner.show()
        
        UIView.animate(withDuration: 2, animations: { [weak self] in
            self?.blurView.alpha = 1
        })
        
        let txid = Flow.ID(hex: txid)
        do {
            let result = try await txid.onceSealed()
            if result.status == .sealed && result.errorMessage == "" {
                let banner = FloatingNotificationBanner(title: "Transaction sealed, tap to view", style: .success)
                banner.onTap = { [weak self] in
                    self?.navigateToTransaction(txid: tx)
                }
                banner.duration = 2
                banner.show()
                fetchFlovatarData {
                    fadeBlurView()
                }
            } else {
                let banner = FloatingNotificationBanner(title: "Transaction failed, tap to view", style: .warning)
                banner.onTap = { [weak self] in
                    self?.navigateToTransaction(txid: tx)
                }
                banner.duration = 2
                banner.show()
                fadeBlurView()
            }
        } catch {
            debugPrint("Transaction failed \(error)")
            let banner = FloatingNotificationBanner(title: "Transaction failed, tap to view", style: .warning)
            banner.onTap = { [weak self] in
                self?.navigateToTransaction(txid: tx)
            }
            banner.duration = 2
            banner.show()
            fadeBlurView()
        }
    }
    
    private func speak(text: String) {
        guard let sub = ProcessInfo.processInfo.environment["SPEECH_KEY"],
              let region = ProcessInfo.processInfo.environment["SPEECH_REGION"] else {
            return
        }
        
        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
            speechConfig!.speechSynthesisVoiceName = "en-US-RogerNeural";
            
            let synthesizer = try! SPXSpeechSynthesizer(speechConfig!)
            let ssml = """
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"
       xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="en-US">
    <voice name="en-US-RogerNeural">
        <mstts:express-as style="excited" styledegree="2">
            \(text)
        </mstts:express-as>
    </voice>
</speak>
"""
            let result = try! synthesizer.speakSsml(ssml)
            
            if result.reason == SPXResultReason.canceled {
                let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
                print("cancelled, error code: \(cancellationDetails.errorCode) detail: \(cancellationDetails.errorDetails!) ")
                print("Did you set the speech resource key and region values?");
                return
            }
            
        } catch {
            print("error \(error) happened")
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "user", context: nil)
    }

}
