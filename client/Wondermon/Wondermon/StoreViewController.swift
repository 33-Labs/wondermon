//
//  StoreViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/11.
//

import UIKit
import Flow
import NotificationBannerSwift
import SafariServices

class StoreViewController: UIViewController {
    
    fileprivate var user: User?
    
    var flovatars: [Flovatar] = []
    var flobits: [Flobit] = []
    var tokens: [Token] = [
        Token(symbol: "FLOW", logo: UIImage(named: "100flow")!),
        Token(symbol: "LOPPY", logo: UIImage(named: "100loppy")!)
    ]
    
    private let numberOfItemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    let collectionView: UICollectionView
    let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "store")

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -8),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }()
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        
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
        loadStoreItems()
    }
    
    private func setupUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(StoreItemCell.self, forCellWithReuseIdentifier: StoreItemCell.reuseIdentifier)
        collectionView.register(StoreCollectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: StoreCollectionHeaderView.reuseIdentifier)
        
        view.addSubview(headerView)
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    private func getUser() {
        self.user = UserDefaults.standard.fetchUser()
    }
    
    private func loadStoreItems() {
        Task { [weak self] in
            guard let sSelf = self else { return }
            do {
                let items = try await sSelf.fetchStoreItems()
                DispatchQueue.main.async {
                    self?.flobits = items.flobits
                    self?.flovatars = items.flovatars
                    self?.collectionView.reloadData()
                }
            } catch {
                print(error)
                // TODO: alert load flobits failed
            }
        }
    }
    
    private func fetchStoreItems() async throws -> StoreItems {
        guard let user = user,
              let _ = user.flowAccount else {
            return StoreItems(flovatars: [], flobits: [])
        }
        
        // NOTE: Just hardcode the store address
        let rawAddress = "0xfd798728acbb0e06"
        let rawScript = fetchStoreItemsScript()
        let script = Flow.Script(text: rawScript)
        let address = Flow.Address(hex: rawAddress)
        
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [.init(value: .address(address))])
        let items: StoreItems = try result.decode()
        return items
    }
    
    private func fetchStoreItemsScript() -> String {
        return """
import Flovatar from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import MetadataViews from 0x1d7e57aa55817448

pub struct FlobitItem {
  pub let id: UInt64
  pub let display: MetadataViews.Display

  init(id: UInt64, display: MetadataViews.Display) {
    self.id = id
    self.display = display
  }
}

pub struct FlovatarItem {
  pub let id: UInt64
  pub let display: MetadataViews.Display

  init(id: UInt64, display: MetadataViews.Display) {
    self.id = id
    self.display = display
  }
}

pub struct StoreItems {
  pub let flovatars: [FlovatarItem]
  pub let flobits: [FlobitItem]

  init(flovatars: [FlovatarItem], flobits: [FlobitItem]) {
    self.flovatars = flovatars
    self.flobits = flobits
  }
}

pub fun main(address: Address): StoreItems {
    let account = getAccount(address)
    let flobitCap = account
      .getCapability(FlovatarComponent.CollectionPublicPath)
      .borrow<&{FlovatarComponent.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Flobit collection")

    let flobits: [FlobitItem] = []
    let flobitIds = flobitCap.getIDs()
    for tokenId in flobitIds {
      let resolver = flobitCap.borrowViewResolver(id: tokenId)
      if let display = MetadataViews.getDisplay(resolver) {
        flobits.append(FlobitItem(id: tokenId, display: display))
      }
    }

    let flovatarCap = account
      .getCapability(Flovatar.CollectionPublicPath)
      .borrow<&{Flovatar.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Flovatar collection")

    let flovatars: [FlovatarItem] = []
    let flovatarIds = flovatarCap.getIDs()
    for tokenId in flovatarIds {
      let resolver = flovatarCap.borrowViewResolver(id: tokenId)
      if let display = MetadataViews.getDisplay(resolver) {
        flovatars.append(FlovatarItem(id: tokenId, display: display))
      }
    }

    return StoreItems(flovatars: flovatars, flobits: flobits)
}
"""
    }
}

// MARK: - UICollectionViewDataSource
extension StoreViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return flovatars.count
        } else if section == 1 {
            return flobits.count
        } else {
            return tokens.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoreItemCell.reuseIdentifier, for: indexPath) as! StoreItemCell
        
        if indexPath.section == 0 {
            let flovatar = flovatars[indexPath.item]
            cell.setFlovatar(flovatar)
            return cell
        } else if indexPath.section == 1 {
            let flobit = flobits[indexPath.item]
            cell.setFlobit(flobit)
            return cell
        } else {
            let token = tokens[indexPath.item]
            cell.setToken(token)
            return cell
        }
    }
}

extension StoreViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let flobit = flobits[indexPath.item]
            NetworkManager.shared.checkout(itemType: "Flobit", tokenId: 2) { [weak self] result in
                switch result {
                case .success(let session):
                    if let url = URL(string: session.sessionURL) {
                        let safariViewController = SFSafariViewController(url: url)
//                        safariViewController.modalPresentationStyle = .overFullScreen
                        DispatchQueue.main.async { [weak self] in
                            self?.present(safariViewController, animated: true, completion: nil)
                        }
                    }
                case .failure(let error):
                    print(error)
                    let banner = FloatingNotificationBanner(title: "Checkout failed", style: .warning)
                    banner.duration = 2
                    banner.show()
                }
            }
            
        } else {
            let banner = FloatingNotificationBanner(title: "Coming soon", style: .info)
            banner.duration = 2
            banner.show()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension StoreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (numberOfItemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / numberOfItemsPerRow
        
        return CGSize(width: widthPerItem, height: 1.25 * widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StoreCollectionHeaderView.reuseIdentifier, for: indexPath) as! StoreCollectionHeaderView
        
        if indexPath.section == 0 {
            headerView.setTitle("Flovatars")
        } else if indexPath.section == 1 {
            headerView.setTitle("Flobits")
        } else {
            headerView.setTitle("Tokens")
        }
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

