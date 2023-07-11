//
//  FlobitsViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import UIKit
import Flow

class FlobitsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    private let numberOfItemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    fileprivate var user: User?
    
    private var flobits: [Flobit] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUser()
        setupCollectionView()
        loadFlobits()
    }
    
    private func setupCollectionView() {
        collectionView.register(FlobitCollectionViewCell.self, forCellWithReuseIdentifier: FlobitCollectionViewCell.reuseIdentifier)
        collectionView.register(FlobitsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FlobitsHeaderView.reuseIdentifier)
    }
    
    private func getUser() {
        self.user = UserDefaults.standard.fetchUser()
    }
    
    private func loadFlobits() {
        Task { [weak self] in
            guard let sSelf = self else { return }
            do {
                let flobits = try await sSelf.fetchFlobits()
                
                DispatchQueue.main.async {
                    sSelf.flobits = flobits
                    sSelf.collectionView.reloadData()
                }
            } catch {
                print(error)
                // TODO: alert load flobits failed
            }
        }
    }
    
    private func fetchFlobits() async throws -> [Flobit] {
        guard let user = user,
              let flowAccount = user.flowAccount else {
            return []
        }
        
        let rawAddress = flowAccount.address
        let rawScript = fetchFlobitsScript()
        let script = Flow.Script(text: rawScript)
        let address = Flow.Address(hex: rawAddress)
        
        let result = try await flow.executeScriptAtLatestBlock(script: script, arguments: [.init(value: .address(address))])
        let flobits: [Flobit] = try result.decode()
        return flobits
    }
    
    private func fetchFlobitsScript() -> String {
        return """
import Flovatar from 0x921ea449dffec68a
import FlovatarComponent from 0x921ea449dffec68a
import MetadataViews from 0x1d7e57aa55817448

pub struct Flobit {
  pub let id: UInt64
  pub let display: MetadataViews.Display

  init(id: UInt64, display: MetadataViews.Display) {
    self.id = id
    self.display = display
  }
}

pub fun main(address: Address): [Flobit] {
    let account = getAccount(address)
    let flobitCap = account
      .getCapability(FlovatarComponent.CollectionPublicPath)
      .borrow<&{FlovatarComponent.CollectionPublic, MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Flovatar collection")

    let res: [Flobit] = []
    let tokenIds = flobitCap.getIDs()
    for tokenId in tokenIds {
      let resolver = flobitCap.borrowViewResolver(id: tokenId)
      if let display = MetadataViews.getDisplay(resolver) {
        res.append(Flobit(id: tokenId, display: display))
      }
    }

    return res
}
"""
    }

    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flobits.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FlobitCollectionViewCell.reuseIdentifier, for: indexPath) as! FlobitCollectionViewCell
        
        let flobit = flobits[indexPath.item]
        cell.setFlobit(flobit)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FlobitsHeaderView.reuseIdentifier, for: indexPath) as! FlobitsHeaderView
            
            return headerView
        } else {
            fatalError("Unsupported supplementary view type")
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (numberOfItemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / numberOfItemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
