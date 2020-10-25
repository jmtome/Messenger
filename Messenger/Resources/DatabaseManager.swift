//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 19/10/2020.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
}

//MARK: - Account Management
extension DatabaseManager {
    
    
    
    
    /// Checks if there is an existing user with the given email account
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
       
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Inserts new user to Database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ]) { (error, databaseReference) in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            
           
            self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    //append to user dictionary
                    let newElement = ["name": user.firstName + " " + user.lastName,
                                      "email": user.safeEmail
                                     ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection) { (error, databaseReference) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                } else {
                    //create that dictionary / array
                    let newCollection: [[String: String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { (error, databaseReference) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
            
         
        }
            
    }
    public func getAllUsers(completion: @escaping (Result<[[String:String]],Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    public enum DatabaseError: Error {
        case failedToFetch
    }
}




struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var profilePictureFileName: String {
        //emailUser-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}


//MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /*
            "sdadasxdas" {
                "messages": [
                    {
                        "id" : String
                        "type" : text, photo, video
                        "content": String
                        "date" : Date()
                        "sender_email" : String
                        "isRead": True/false
                    
                    }
                ]
            }
     
     
            conversation => [
        [
            "conversationID": "sdadasxdas"
            "other_user_email":
            "latest_message": => {
                "date": Date()
                "latest_message": "message"
                "is_read": true/false
            }
        
        ]
     ]
     */
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let reference = database.child("\(safeEmail)")
        reference.observeSingleEvent(of: .value) { (snapshot) in
            guard var userNode = snapshot.value as? [String : Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID ,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date":dateString ,
                    "is_read": false,
                    "message": message
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists for current user ,
                //you should append
                conversations.append(newConversationData)
                userNode["conversatios"] = conversations
                reference.setValue(userNode) { [weak self] (error, databaseReference) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
                
            } else {
                //conv array does not exist, we create one
                userNode["conversations"] = [newConversationData]
                
                reference.setValue(userNode) { [weak self] (error, databaseReference) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            }
            
        }
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
//        "messages": [
//            {
//                "id" : String
//                "type" : text, photo, video
//                "content": String
//                "date" : Date()
//                "sender_email" : String
//                "isRead": True/false
//
//            }
//        ]
        
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myemail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myemail)
        
        let collectionMessage: [String: Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail ,
            "is_red": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        
        ]
        
        print("adding conversation: \(conversationID)")
        
        database.child("\(conversationID)").setValue(value) { (error, databaseReference) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String,Error>) -> Void) {
        
    }
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
    
}
