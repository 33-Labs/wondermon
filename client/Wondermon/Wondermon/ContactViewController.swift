//
//  ContactViewController.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/10.
//

import UIKit
import Flow
import NotificationBannerSwift

class ContactViewController: UIViewController {
    
    var contacts: [Contact] = []
    
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
        
        let button = UIButton(type: .contactAdd)
        button.tintColor = .wm_deepPurple
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.addTarget(self, action: #selector(addContactButtonTapped), for: .touchUpInside)
        
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
        fetchContacts()
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
    
    func fetchContacts() {
        NetworkManager.shared.getContacts { [weak self] result in
            switch result {
            case .success(let contacts):
                self?.contacts = contacts
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
                let banner = FloatingNotificationBanner(title: "Fetch contacts failed", style: .warning)
                banner.duration = 1
                banner.show()
            }
        }
    }
    
    @objc func addContactButtonTapped() {
        let alertController = UIAlertController(title: "New Contact",
                                                message: nil,
                                                preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Name"
        }

        alertController.addTextField { (textField) in
            textField.placeholder = "Flow Address"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (action) in
            guard let nameField = alertController.textFields?.first,
                  let addressField = alertController.textFields?.last,
                  let name = nameField.text,
                  let address = addressField.text else {
                return
            }
            
            Task { [weak self] in
                let isValidAddress = await Flow.shared.isAddressVaildate(address: Flow.Address(hex: address))
                guard isValidAddress else {
                    let banner = FloatingNotificationBanner(title: "Invalid address", style: .warning)
                    banner.duration = 1
                    banner.show()
                    return
                }
                
                NetworkManager.shared.addContact(name: name, address: address) { [weak self] result in
                    switch result {
                    case .success(let contact):
                        self?.contacts.append(contact)
                        DispatchQueue.main.async { [weak self] in
                            self?.tableView.reloadData()
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
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
            let contact = contacts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            NetworkManager.shared.deleteContact(contactId: contact.id) { result in
                print(result)
            }
        }
    }
}




