//
//  FlovatarViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/7.
//

import UIKit
import Flow
import Macaw

class FlovatarViewController: UIViewController {
    
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        view.backgroundColor = .purple
        setupImageView()
        fetchFlovatarData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")

    }
    
    private func fetchFlovatarData() {
        DispatchQueue.global().async {
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

    }
    
    private func setupImageView() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        imageView.addSubview(svgView)
        svgView.translatesAutoresizingMaskIntoConstraints = false
        svgView.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        svgView.heightAnchor.constraint(equalTo: svgView.widthAnchor).isActive = true
        svgView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        svgView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
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
}
