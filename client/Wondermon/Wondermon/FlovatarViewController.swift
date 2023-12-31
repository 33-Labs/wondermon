//
//  FlovatarViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit
import Flow
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
    
    private var flovatarName: String = "Frank"
    
    private var convertedText: String? {
        willSet {
            guard shouldRecord else {
                return
            }
        }
        didSet {
            guard shouldRecord else {
                return
            }
            
            if let user = user,
               let convertedText = convertedText,
               let flovatarId = flovatarId,
                convertedText.count > 0 {
                speakView.text = "\(user.name): \(convertedText)\n"
                chat(prompt: convertedText, flovatarId: flovatarId)
            } else {
                speakView.text = ""
            }
        }
    }
    
    var shouldRecord = true
    
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
    
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.cornerRadius = 30

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
    
    private lazy var audioImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    let startImage = UIImage(named: "holdtotalk")
    let stopImage = UIImage(named: "releasetosend")
    private lazy var audioButton: UIView = {
        let view = UIView()
        
        view.addSubview(audioImageView)
        audioImageView.translatesAutoresizingMaskIntoConstraints = false
        audioImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        audioImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        audioImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        audioImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
        audioImageView.image = startImage
        audioImageView.isUserInteractionEnabled = true
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 0.3
        longPressGestureRecognizer.allowableMovement = 10
        view.addGestureRecognizer(longPressGestureRecognizer)
        return view
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
                    self.audioButton.isUserInteractionEnabled = true
                } else {
                    self.audioButton.isUserInteractionEnabled = false
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //路径阴影
        let path = UIBezierPath(roundedRect: shadowView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 50, height: 50))
        //设置阴影路径
        shadowView.layer.shadowPath = path.cgPath
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
                    let flovatar = try await self.fetchBasicFlovatar(rawAddress: rawAddress, flovatarId: tokenId)
                    let rawSvg = flovatar.svg
                    flovatarName = flovatar.name == "" ? "Frank" : flovatar.name
                    let svg = addSvgAnimation(svg: rawSvg)
                    DispatchQueue.main.async { [weak self] in
                        guard let sSelf = self else { return }
                        sSelf.webView.loadHTMLString("<div style=\"width: 100%; height: 100%;\">\(svg)</div>", baseURL: nil)
                        completion?()
                    }
                } else {
                    cleanFlovatar()
                    alertNoFlovatar()
                }
            } catch {
                cleanFlovatar()
                alertNoFlovatar()
            }
        }
    }
    
    private func alertNoFlovatar() {
        let banner = FloatingNotificationBanner(title: "No Flovatar Found", subtitle: "Please transfer 1 Flovatar to your address (which can be found on the Profile page)", style: .warning)
        banner.dismissOnSwipeUp = true
        banner.dismissOnTap = true
        banner.duration = 4
        banner.show()
    }
    
    private func addSvgAnimation(svg: String) -> String {
        let ext = """
        <defs><style>.cls-1-441{fill:none;stroke:#000;stroke-linecap:round;stroke-miterlimit:10;stroke-width:13px;}.cls-2-441{opacity:0.24;}</style></defs>
        
        <g id="Mouth_Smile" style="visibility: hidden;"><path class="cls-1-441" d="M1846.08,1506.27c0,15.86-44.86,28.73-100.2,28.73s-100.19-12.87-100.19-28.73"/><path class="cls-2-441" d="M1842.61,1539.4c14.7-6-17.39,43.39-95.87,43.39-53,0-95.87-27.52-95.87-43.39C1650.87,1539.4,1735.77,1582.84,1842.61,1539.4Z"/></g>

        <animate id="smile_anim" attributeName="visibility" from="hidden" to="visible" begin="indefinite" dur="0.4s" repeatCount="indefinite" href="#Mouth_Smile" />
        <animate id="tooth_grin_anim" attributeName="visibility" from="hidden" to="visible" begin="indefinite" dur="0.4s" repeatCount="indefinite" href="#Mouth_ToothGrin" />
        """
        
        let pattern = "<g id=\"Mouth_ToothGrin\">(.+?)</g>"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        if let match = regex.firstMatch(in: svg, options: [], range: NSRange(location: 0, length: svg.utf16.count)) {
            let matchedRange = match.range
            let insertionIndex = svg.index(svg.startIndex, offsetBy: matchedRange.upperBound + 1)
            var modifiedSvg = svg
            modifiedSvg.insert(contentsOf: "\n\(ext)", at: insertionIndex)
            return modifiedSvg
        }
        
        return svg
    }
    
    func playAnimation() {
        let javascript = """
            var smileAnimate = document.getElementById('smile_anim');
            var toothGrinAnimate = document.getElementById('tooth_grin_anim');
            smileAnimate.beginElement();
          setTimeout(function() {
                        toothGrinAnimate.beginElement();
          }, 200);
            
        """
        webView.evaluateJavaScript(javascript) { (result, error) in
            if let error = error {
                print("JavaScript error: \(error)")
            }
        }
    }
    
    func stopAnimation() {
        let javascript = """
            var smileAnimate = document.getElementById('smile_anim');
            var toothGrinAnimate = document.getElementById('tooth_grin_anim');
            smileAnimate.endElement();
            toothGrinAnimate.endElement();
        """
        webView.evaluateJavaScript(javascript) { (result, error) in
            if let error = error {
                print("JavaScript error: \(error)")
            }
        }
    }
    
    private func cleanFlovatar() {
        flovatarId = nil
    }
    
    private func setupUI() {
        view.addSubview(shadowView)
        shadowView.backgroundColor = .yellow
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        shadowView.heightAnchor.constraint(equalTo: shadowView.widthAnchor).isActive = true
        shadowView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -88).isActive = true
        shadowView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        contentView.heightAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -88).isActive = true
        contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        contentView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: 8).isActive = true
        webView.heightAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
        webView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        webView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        contentView.addSubview(unauthenticatedCoverView)
        unauthenticatedCoverView.translatesAutoresizingMaskIntoConstraints = false
        unauthenticatedCoverView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        unauthenticatedCoverView.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        unauthenticatedCoverView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        unauthenticatedCoverView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        let promptButton = UIButton()
        promptButton.tintColor = .wm_purple
        promptButton.addTarget(self, action: #selector(promptButtonTapped), for: .touchUpInside)
        let image = UIImage(named: "flovatar_simple")
        promptButton.setImage(image, for: .normal)
        contentView.addSubview(promptButton)
        promptButton.translatesAutoresizingMaskIntoConstraints = false
        promptButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        promptButton.heightAnchor.constraint(equalTo: promptButton.widthAnchor).isActive = true
        promptButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        promptButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        
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
        stackView.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 16).isActive = true
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
    
    private func fetchBasicFlovatar(rawAddress: String, flovatarId: UInt64) async throws -> BasicFlovatar {
        let rawScript = fetchBasicFlovatarScript()
        let script = Flow.Script(text: rawScript)
        let address = Flow.Address(hex: rawAddress)
        
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [
            .init(value: .address(address)),
            .init(value: .uint64(flovatarId))
        ])
        let basicFlovatar: BasicFlovatar = try result.decode()
        return basicFlovatar
        
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
    
    private func fetchBasicFlovatarScript() -> String {
        return """
        import Flovatar from 0x921ea449dffec68a
        pub struct BasicFlovatar {
            pub let name: String
            pub let svg: String
        
            init(name: String, svg: String) {
                self.name = name
                self.svg = svg
            }
        }

        pub fun main(address: Address, flovatarId: UInt64): BasicFlovatar {
          let account = getAuthAccount(address)

          let flovatarCap = account
            .getCapability(Flovatar.CollectionPublicPath)
            .borrow<&{Flovatar.CollectionPublic}>()
            ?? panic("Could not borrow flovatar public collection")

          let flovatar = flovatarCap.borrowFlovatar(id: flovatarId)
            ?? panic("Could not borrow flovatar with that ID from collection")

          let svg = flovatar.getSvg()
          let res = BasicFlovatar(name: flovatar.getName(), svg: svg)
          return res
        }
        """
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            guard let _ = user else {
                let vc = LoginViewController()
                present(vc, animated: true, completion: nil)
                return
            }
            
            guard let _ = flovatarId else {
                alertNoFlovatar()
                return
            }
            shouldRecord = true
            if !audioEngine.isRunning {
                startRecording()
            }
            audioImageView.image = stopImage
        } else if gestureRecognizer.state == .changed {
            let touchLocation = gestureRecognizer.location(in: self.view)
            if !audioButton.frame.contains(touchLocation) {
                shouldRecord = false
                audioImageView.image = UIImage(named: "releasetocancel")
            } else {
                shouldRecord = true
                audioImageView.image = stopImage
            }
        } else if gestureRecognizer.state == .ended {
            audioImageView.image = startImage
            stopRecording()
        }
    }
    
    private func startRecording() {
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
    
    @objc func promptButtonTapped(_ sender: UIButton) {
        guard let _ = user else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
            return
        }
        
        guard let flovatarId = flovatarId else {
            alertNoFlovatar()
            return
        }
        
        let vc = PromptViewController(flovatarId: flovatarId)
        present(vc, animated: true, completion: nil)
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
                    sSelf.speakView.text = "\(sSelf.flovatarName): \(message.message)"
                    DispatchQueue.global().async { [weak self] in
                        self?.speak(text: message.message)
                    }
                } else {
                    print("Message persist failed")
                }
                
                DispatchQueue.main.async { [weak self] in
                    Task {
                        if let txid = message.txid {
                            await self?.handleFlovatarRelatedTxid(txid)
                        } else if let command = message.command {
                            self?.handleCommand(command)
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
    
    private func handleCommand(_ command: [String: String]) {
        if let action = command["action"],
           let token = command["token"],
           let amount = command["amount"],
           let recipient = command["recipient"],
            action == "send_token" {
            let content = "Send \(amount) \(token.uppercased()) to \(recipient)"
            let alertController = UIAlertController(title: "Review Transaction", message: content, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in

                NetworkManager.shared.sendToken(symbol: token, recipient: recipient, amount: amount) { [weak self] result in
                    Task {
                        switch result {
                        case .success(let txid):
                            await self?.watchTransaction(transactionHash: txid.txid)
                        case .failure(let error):
                            print("handleCommand error: \(error)")
                        }
                    }
                }
            }
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        } else if let action = command["action"],
                  action == "present",
                  let rawPage = command["page"] {
            let page = rawPage.lowercased()
            switch page {
            case "flobit":
                let vc = FlobitsCollectionViewController()
                present(vc, animated: true)
            case "tokens", "token":
                let vc = TokensViewController()
                present(vc, animated: true)
            case "store":
                let vc = StoreViewController()
                present(vc, animated: true)
            case "contacts", "contact":
                let vc = ContactViewController()
                present(vc, animated: true)
            default:
                return
            }
        }
    }
    
    private func showAndDoSpeak(text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            sSelf.speakView.text = "\(sSelf.flovatarName): \(text)"
            sSelf.speak(text: text)
        }
    }
    
    private func handleFlovatarRelatedTxid(_ txid: String) async {
        UIView.animate(withDuration: 2, animations: { [weak self] in
            self?.blurView.alpha = 1
        })
        
        await watchTransaction(transactionHash: txid) { [weak self] in
            self?.fetchFlovatarData {
                self?.fadeBlurView()
            }
        } onFailure: { [weak self] in
            self?.fadeBlurView()
        }
    }
    
    func fadeBlurView() {
        UIView.animate(withDuration: 2, animations: { [weak self] in
            self?.blurView.alpha = 0
        })
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
    
    var synthesizer: SPXSpeechSynthesizer?
    private func speak(text: String, completion: (() -> Void)? = nil) {
        guard let user = user else {
            print("[Speak] Unauthorized")
            return
        }
        let sub = user.speechKey
        let region = user.speechRegion
        
        var speechConfig: SPXSpeechConfiguration?
        do {
            if let syn = synthesizer {
                try syn.stopSpeaking()
                synthesizer = nil
            }
            
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
            speechConfig!.speechSynthesisVoiceName = "en-US-RogerNeural";
            
            synthesizer = try! SPXSpeechSynthesizer(speechConfig!)
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.playAnimation()
            }
            guard let result = try! synthesizer?.speakSsml(ssml) else {
                DispatchQueue.main.async { [weak self] in
                    self?.stopAnimation()
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.stopAnimation()
            }
            
            if result.reason == SPXResultReason.canceled {
                let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
                print("cancelled, error code: \(cancellationDetails.errorCode) detail: \(cancellationDetails.errorDetails!) ")
                print("Did you set the speech resource key and region values?");
            }
            completion?()
        } catch {
            print("error \(error) happened")
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "user", context: nil)
    }

}
