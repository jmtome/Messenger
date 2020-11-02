//
//  ViewController.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 18/10/2020.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
    
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
    
}

class ConversationsViewController: UIViewController {

    
    
    private var loginObserver: NSObjectProtocol?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    
    private let tableView: UITableView! = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(ConversationTableViewCell.self,
                           forCellReuseIdentifier: ConversationTableViewCell.identifier)
        
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
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                               object: nil,
                                               queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            
            self.navigationController?.dismiss(animated: true, completion: nil)
            
            self.startListeningForConversations()
        }
        
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
         
        print("Starting conversation fetch...")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] (result) in
            switch result {
            
            case .success(let conversations):
                print("successfully got conversation models")
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("failed with error: \(error)")
            }
        }
    }
    
    @objc func didTapComposeButton(_ sender: UIBarButtonItem) {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in

            self?.createNewConversation(result: result)
            
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = result.email
        
        
        DatabaseManager.shared.conversationExists(with: email) { [weak self] (result) in
            switch result {
            case .success(let conversationID):
                let vc = ChatViewController(with: email, id: conversationID)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
                
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(vc, animated: true)
                
                
            }
        }
        
        
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
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        let vc = ChatViewController(with: model.otherUserEmail,id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //begin delete
            
            let conversationID = conversations[indexPath.row].id
            
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationID) { [weak self] (success) in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .left)
                    
                }
            }
            
            
            tableView.endUpdates()
        }
    }
}
