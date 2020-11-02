//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 18/10/2020.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

class ProfileViewController: UIViewController {

    
    @IBOutlet var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", handler: nil))
        
        data.append(ProfileViewModel(viewModelType: .logout, title: "Logout", handler: { [weak self] in
            
            
            let actionSheet = UIAlertController(title: "Are you sure you want to log out?",
                                                message: "Logging out will log you out ",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                
                //Log Out Facebook
                FBSDKLoginKit.LoginManager().logOut()
                
                //Log Out Google
                GIDSignIn.sharedInstance()?.signOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                    
                } catch let error {
                    print("there was an error: \(error) signing out")
                }
                
            }))
            
            self?.present(actionSheet, animated: true, completion: nil)
        }))
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (view.width - 150) / 2, y: 75, width: 150, height: 150))
        
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        
        StorageManager.shared.downloadURL(for: path) { [weak self] (result) in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("failed to get download url :\(error)")
            }
        }
        
        headerView.addSubview(imageView)

        return headerView
        
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        
        imageView.sd_setImage(with: url, completed: nil)
//        let session = URLSession.shared
//        let task = session.dataTask(with: url) { (data, response, error) in
//            guard let data = data, error == nil else {
//                return
//            }
//            DispatchQueue.main.async {
//                let image = UIImage(data: data)
//                imageView.image = image
//            }
//        }.resume()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
       
        let viewModel = data[indexPath.row]
        cell.setup(with: viewModel)
       
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let viewModel = data[indexPath.row].handler?()
        
        
    }
    
}

class ProfileTableViewCell: UITableViewCell {
    
    
    static let identifier = "ProfileTableViewCell"
    
    public func setup(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
            
        }
    }
}
    
