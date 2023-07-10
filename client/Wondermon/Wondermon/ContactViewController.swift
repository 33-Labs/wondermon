//
//  ContactViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/10.
//

import UIKit

struct Contact {
    let name: String
    let address: String
}

class ContactViewController: UIViewController {
    
    var contacts: [Contact] = [
        Contact(name: "lanford", address: "0xb072ae75f8858c93"),
        Contact(name: "lanford2", address: "0xb072ae75f8858c94")
    ]
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "contacts")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: "ContactCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

    }
    
    func setupUI() {
        view.addSubview(headerView)
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    @objc func addContact() {
        
    }
}

extension ContactViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as! ContactTableViewCell
        
        let contact = contacts[indexPath.row]
        cell.nameLabel.text = contact.name
        cell.addressLabel.text = contact.address
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            contacts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}




