//
//  LoginViewController.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 18/10/2020.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {

    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView! = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView! = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
        
    }()
    
    private let emailField: UITextField! = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField! = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        //cuts what overflows the corner borders
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button =  FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    private let googleLoginButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,
                                               object: nil,
                                               queue: .main) { [weak self] (notification) in
            guard let self = self else { return }
            
            self.navigationController?.dismiss(animated: true, completion: nil)
            
        }
        
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        facebookLoginButton.delegate = self
        
        //Add Subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
        
        //according to fb docs this might have to be used
//        if let token = AccessToken.current,
//           !token.isExpired {
//            // User is logged in, do work such as go to next view controller.
//        }
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        facebookLoginButton.frame = CGRect(x: 30,
                                   y: loginButton.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        googleLoginButton.frame = CGRect(x: 30,
                                   y: facebookLoginButton.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        //Firebase Login
        
        spinner.show(in: view)
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            

            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            guard let result = authResult, error == nil else {
                print("Error signing in with email:\(email)")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            
                
            
            DatabaseManager.shared.getDataFor(path: safeEmail) { (result) in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
                    
                case .failure(let error):
                    print("failed to read data with error: \(error)")
                }
            }
            
            UserDefaults.standard.set(email, forKey: "email")

            
            print("Successfully signed in with user :\(user)")
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
        
        
    }
}


extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
        print("Use logged out")
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
            
        }
        
        //facebook login
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields":"email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { (connection, result, error) in
            guard let result = result as? [String:Any], error == nil else {
                print("failed to make facebook graph request")
                return
            }
            
            print("\(result)")
            
            
           
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureURL = data["url"] as? String else {
                print("Failed to get email and name from FBResults")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
          
            DatabaseManager.shared.userExists(with: email) { (exists) in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName,  emailAddress: email)

                    DatabaseManager.shared.insertUser(with: chatUser) { (success) in
                        if success {
                            
                            guard let url = URL(string: pictureURL) else {
                                print("bad picture url")
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            
                            let session = URLSession.shared.dataTask(with: url) { (data, response, error) in
                                guard let data = data, error == nil else {
                                    if let error = error {
                                        print("failed to get data with error: \(error)")
                                    }
                                    return
                                }
                                
                                print("got data from facebook, uploading ")
                                //upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                    switch result {
                                    case .success(let downloadURL):
                                        print(downloadURL)
                                        UserDefaults.standard.setValue(downloadURL, forKey: "profilePictureURL")
                                    case .failure(let error):
                                        print("storage manager error: \(error)")
                                    }
                                }
                            }
                            session.resume()
                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                guard let self = self else { return }
                
                guard authResult != nil , error == nil else {
                    if let error = error {
                        print("Facebook login credential failed, MFA may be needed \(error)")
                    }
                    return
                }
                print("Successfully logged user in")
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    
}
