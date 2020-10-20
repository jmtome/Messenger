//
//  ViewController.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 18/10/2020.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(FirebaseAuth.Auth.auth().currentUser)
        validateAuth()
       
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

