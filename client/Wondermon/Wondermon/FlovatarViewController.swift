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

class FlovatarViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private lazy var svgView: SVGView = {
        let node = try! SVGParser.parse(resource: "placeholder", ofType: "svg")
        let svgView = SVGView(node: node, frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        return svgView
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .green

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
    private var convertedText: String?

    private lazy var audioButton: UIButton = {
        let button = UIButton()
        button.setTitle("Speak", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Stop", for: .focused)
        button.setTitle("Stop", for: .highlighted)
        button.setTitle("Stop", for: .disabled)
        button.backgroundColor = .yellow
        
        button.addTarget(self, action: #selector(audioButtonTapped), for: .touchDown)
        button.addTarget(self, action: #selector(audioButtonTapped), for: .touchUpInside)
        button.addTarget(self, action: #selector(audioButtonTapped), for: .touchUpOutside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        view.backgroundColor = .purple
        setupUI()
        setupAudio()
        fetchFlovatarData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")

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
    
    private func fetchFlovatarData() {
        Task {
            do {
                let rawAddress = "0xb3f51e9437851f08"
                let tokenIds = try await self.fetchFlovatarIds(rawAddress: rawAddress)
                if (tokenIds.count > 0) {
                    let tokenId = tokenIds[0]
                    let svg = try await self.fetchFlovatarSvg(rawAddress: rawAddress, flovatarId: tokenId)
                    let node = try SVGParser.parse(text: svg)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let sSelf = self else { return }
                        sSelf.svgView.node = node
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -50).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        imageView.addSubview(svgView)
        svgView.translatesAutoresizingMaskIntoConstraints = false
        svgView.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        svgView.heightAnchor.constraint(equalTo: svgView.widthAnchor).isActive = true
        svgView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        svgView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        
        view.addSubview(audioButton)
        audioButton.translatesAutoresizingMaskIntoConstraints = false
        audioButton.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -60).isActive = true
        audioButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        audioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        audioButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
    }
    
    private func fetchFlovatarSvg(rawAddress: String, flovatarId: UInt64) async throws -> String {
        print("fetchFlovatar")
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
        print("fetchFlovatarIds")
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
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecording()
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
}
