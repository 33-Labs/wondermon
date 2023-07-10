//
//  ProfileViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/10.
//

import UIKit
import Flow

class TokensViewController: UIViewController {
    
    private var user: User? {
        didSet {
            fetchData()
        }
    }
    
    private let flowToken = Token(symbol: "FLOW", logo: UIImage(named: "flow")!)
    private let loppyToken = Token(symbol: "LOPPY", logo: UIImage(named: "loppy")!)
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "tokens")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        return view
    }()
    
    private lazy var flowView: TokenView = {
        let view = TokenView(frame: .zero)
        return view
    }()
    
    private lazy var loppyView: TokenView = {
        let view = TokenView(frame: .zero)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupUI()
        getUser()
        
    }
    
    private func setupUI() {
        view.addSubview(headerView)
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        view.addSubview(flowView)
        flowView.translatesAutoresizingMaskIntoConstraints = false
        flowView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 48).isActive = true
        flowView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        flowView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        flowView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        flowView.setToken(flowToken)
        
        view.addSubview(loppyView)
        loppyView.translatesAutoresizingMaskIntoConstraints = false
        loppyView.topAnchor.constraint(equalTo: flowView.bottomAnchor, constant: 24).isActive = true
        loppyView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        loppyView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        loppyView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        loppyView.setToken(loppyToken)
    }
    
    private func getUser() {
        self.user = UserDefaults.standard.fetchUser()
    }
    
    private func fetchData() {
        guard let user = user,
            let flowAccount = user.flowAccount else {
            cleanData()
            return
        }
        
        Task {
            do {
                let rawAddress = flowAccount.address
                let balances = try await self.fetchTokenBalances(rawAddress: rawAddress)
                setBalances(balances)
            } catch {
                print(error)
                cleanData()
            }
        }

    }
    
    private func cleanData() {
        flowView.setBalance(0.0)
        loppyView.setBalance(0.0)
    }
    
    private func setBalances(_ balances: [String: Decimal]) {
        if let flowBalance = balances["flow"] {
            flowView.setBalance(flowBalance)
        }
        
        if let loppyBalance = balances["loppy"] {
            loppyView.setBalance(loppyBalance)
        }
    }
    
    private func fetchTokenBalances(rawAddress: String) async throws -> [String: Decimal] {
        let rawScript = fetchTokenBalancesScript()
        let script = Flow.Script(text: rawScript)
        let address = Flow.Address(hex: rawAddress)
        
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [.init(value: .address(address))])
        let balances: [String: Decimal] = try result.decode()
        return balances
    }
    
    private func fetchTokenBalancesScript() -> String {
        return """
        import FlowToken from 0x1654653399040a61
        import SloppyStakes from 0x53f389d96fb4ce5e
        import FungibleToken from 0xf233dcee88fe0abe

        pub fun main(address: Address): {String: UFix64} {
          let account = getAccount(address)

          var flowBalance: UFix64 = 0.0
          let flowCap = account.getCapability<&FlowToken.Vault{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()
          if let flow = flowCap {
            flowBalance = flow.balance
          }

          let loppyBalance = SloppyStakes.getBalance(address: address)

          return {
            "flow": flowBalance,
            "loppy": loppyBalance
          }
        }
        """
    }
}
