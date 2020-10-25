//
//  ViewController.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 18/10/2020.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {

    
    
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let tableView: UITableView! = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    private let noConversationsLabel: UILabel! = {
        let label = UILabel()
        label.text = "No Conversations"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton(_:)))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setupTableView()
        fetchConversations()
        
        
    }
    
    @objc func didTapComposeButton(_ sender: UIBarButtonItem) {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in

            self?.createNewConversation(result: result)
            
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    private func createNewConversation(result: [String: String]) {
        guard let name = result["name"],
              let email = result["email"] else {
                    return
        }
        
        let vc = ChatViewController(with: email)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(FirebaseAuth.Auth.auth().currentUser)
        validateAuth()
       
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func fetchConversations() {
        tableView.isHidden = false
    }
    func validateAuth() {
        //for some reason when registering the currentUser doesnt get set and it reads its nil
        
        if FirebaseAuth.Auth.auth().currentUser == nil  {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
            
        }
    }
    

}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello World"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = ChatViewController(with: "fake@fakmail.com")
        vc.title = "Jenny Smith"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
