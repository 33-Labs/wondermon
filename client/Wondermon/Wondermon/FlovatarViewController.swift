//
//  FlovatarViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit
import Flow
import Macaw
import Speech
import AVFoundation
import MicrosoftCognitiveServicesSpeech

class FlovatarViewController: UIViewController, UINavigationBarDelegate, SFSpeechRecognizerDelegate {
    
    private var user: User? {
        didSet {
            fetchFlovatarData()
        }
    }
    
    private var flovatarNode: Node? {
        didSet {
            if let node = flovatarNode {
                svgView.node = node
                svgView.isHidden = false
                unauthenticatedCoverView.isHidden = true
            } else {
                svgView.isHidden = true
                unauthenticatedCoverView.isHidden = false
            }
        }
    }
    
    private var flovatarId: UInt64?
    
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
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.wm_deepPurple.cgColor
        view.clipsToBounds = true
        view.font = .systemFont(ofSize: 16)
        view.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return view
    }()
    
    private lazy var svgView: SVGView = {
        let node = try! SVGParser.parse(resource: "placeholder", ofType: "svg")
        let svgView = SVGView(node: node, frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        return svgView
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 30
        view.clipsToBounds = true

        return view
    }()
    
    private lazy var flobitsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "flobits"), for: .normal)
        button.addTarget(self, action: #selector(flobitsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var unauthenticatedCoverView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.tintColor = .wm_purple
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
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
    
    private lazy var speakButton: UIButton = {
        let button = UIButton()
        button.setTitle("Speak", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(speakButtonTapped), for: .touchDown)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        UserDefaults.standard.addObserver(self, forKeyPath: "user", options: .new, context: nil)
        
        getUser()
        
        view.backgroundColor = .wm_purple
        setupNavigationBar()
        setupUI()
        setupAudio()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "user" {
            print("KVO get user")
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
            try audioSession.setCategory(.record, mode: .default)
        } catch {
            print("setup audioSession failed")
        }
    }
    
    private func getUser() {
        self.user = UserDefaults.standard.fetchUser()
    }
    
    private func fetchFlovatarData() {
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
                    let node = try SVGParser.parse(text: svg)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let sSelf = self else { return }
                        sSelf.flovatarNode = node
                    }
                } else {
                    cleanFlovatar()
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func cleanFlovatar() {
        flovatarId = nil
        flovatarNode = nil
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -72).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        imageView.addSubview(svgView)
        svgView.translatesAutoresizingMaskIntoConstraints = false
        svgView.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        svgView.heightAnchor.constraint(equalTo: svgView.widthAnchor).isActive = true
        svgView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        svgView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        
        imageView.addSubview(unauthenticatedCoverView)
        unauthenticatedCoverView.translatesAutoresizingMaskIntoConstraints = false
        unauthenticatedCoverView.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        unauthenticatedCoverView.heightAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        unauthenticatedCoverView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        unauthenticatedCoverView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        
        view.addSubview(flobitsButton)
        flobitsButton.translatesAutoresizingMaskIntoConstraints = false
        flobitsButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        flobitsButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        flobitsButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        flobitsButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5).isActive = true
        
        view.addSubview(audioButton)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButton.widthAnchor.constraint(equalToConstant:  280).isActive = true
        audioButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        audioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        audioButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40).isActive = true
        
        view.addSubview(speakView)
        speakView.translatesAutoresizingMaskIntoConstraints = false
        speakView.topAnchor.constraint(equalTo: flobitsButton.bottomAnchor, constant: 16).isActive = true
        speakView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        speakView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        speakView.bottomAnchor.constraint(equalTo: audioButton.topAnchor, constant: -16).isActive = true
        
//        view.addSubview(speakButton)
//        speakButton.translatesAutoresizingMaskIntoConstraints = false
//        speakButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
//        speakButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        speakButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        speakButton.bottomAnchor.constraint(equalTo: audioButton.topAnchor, constant: -20).isActive = true
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
        if let user = user {
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
                    print("Recognized Text: \(recognizedText)")
                    if result.isFinal {
                        sSelf.convertedText = recognizedText
                        print("Converted: \(sSelf.convertedText!)")
                        finished = true
                    }
                }
                
                if let error = error {
                    print("Recognition error: \(error)")
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
    
    @objc func speakButtonTapped(_ sender: UIButton) {
        speak(text: "How many roads must a man walk down, before you call him a man")
    }
    
    @objc func flobitsButtonTapped(_ sender: UIButton) {
        if let user = user {
            let vc = FlobitsCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }

    }
    
    @objc func profileButtonTapped(_ sender: UIBarButtonItem) {
        if let user = user {
            let vc = ProfileViewController()
            present(vc, animated: true, completion: nil)
        } else {
            let vc = LoginViewController()
            present(vc, animated: true, completion: nil)
        }
    }
    
    private func chat(prompt: String, flovatarId: UInt64) {
        NetworkManager.shared.chat(prompt: prompt, flovatarId: flovatarId, messages: []) { [weak self] result in
            guard let sSelf = self else { return }
            print(result)
            switch result {
            case .success(let message):
                sSelf.speakView.text = "Flora: \(message.message)"
                DispatchQueue.global().async { [weak self] in
                    self?.speak(text: message.message)
                }
                
                if let txid = message.txid {
                    print(txid)
                }
            case .failure(let error):
                print(error)
            }
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
            let result = try! synthesizer.speakText(text)
            if result.reason == SPXResultReason.canceled {
                let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
                print("cancelled, error code: \(cancellationDetails.errorCode) detail: \(cancellationDetails.errorDetails!) ")
                print("Did you set the speech resource key and region values?");
                return
            }
            
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "user", context: nil)
    }

}
