//
//  StoreViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/11.
//

import UIKit

class StoreViewController: UIViewController {
    
    var flovatars: [Flovatar] = [
        Flovatar(id: 1), Flovatar(id: 2)
    ]
    var flobits: [Flobit] = [
        Flobit(id: 0, display: FlobitDisplay(name: "A", description: "", thumbnail: HTTPFile(url: ""))),
        Flobit(id: 0, display: FlobitDisplay(name: "B", description: "", thumbnail: HTTPFile(url: ""))),
        Flobit(id: 0, display: FlobitDisplay(name: "C", description: "", thumbnail: HTTPFile(url: "")))
    ]
    
    private let numberOfItemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    let collectionView: UICollectionView
    let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .wm_purple
        view.translatesAutoresizingMaskIntoConstraints = false
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
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(StoreFlovatarCell.self, forCellWithReuseIdentifier: StoreFlovatarCell.reuseIdentifier)
        collectionView.register(StoreFlobitCell.self, forCellWithReuseIdentifier: StoreFlobitCell.reuseIdentifier)
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
}

// MARK: - UICollectionViewDataSource
extension StoreViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return flovatars.count
        } else {
            return flobits.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoreFlovatarCell.reuseIdentifier, for: indexPath) as! StoreFlovatarCell
            let flovatar = flovatars[indexPath.item]
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoreFlobitCell.reuseIdentifier, for: indexPath) as! StoreFlobitCell
            let flobit = flobits[indexPath.item]
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension StoreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (numberOfItemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / numberOfItemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StoreCollectionHeaderView.reuseIdentifier, for: indexPath) as! StoreCollectionHeaderView
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

