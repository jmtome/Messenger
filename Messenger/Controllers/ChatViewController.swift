//
//  ChatViewController.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 21/10/2020.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
    
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    
}

struct Location: LocationItem {
    var location: CLLocation
    
    var size: CGSize
    
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

//min 21:45
struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}



class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationID: String?
    
    private var messages = [Message]()

    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail =  DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
        
    }
    
    
    
    init(with email: String, id: String?) {
        self.conversationID = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

         
        
        view.backgroundColor = .red

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
        
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 36, height: 36), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] (button) in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet() {
    
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] (action) in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] (action) in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] (action) in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] (action) in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.title = "Pick Location"
        vc.completion = { [weak self] selectedCoordinates in
            
            guard let self = self else { return }
            
            guard let messageID = self.createMessageID(),
                  let conversationID = self.conversationID,
                  let name = self.title,
                  let selfSender = self.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            print("long=\(longitude) | lat=\(latitude)")
         
            
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                if success {
                    print("Sent location message")
                } else {
                    print("failed to send location message ")
                }
        
            }
            
        }
        navigationController?.pushViewController(vc, animated: true)
        
    }
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (action) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] (action) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (action) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] (action) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        if let conversationID = conversationID {
            listenForMessages(id: conversationID, shouldScrollToBottom: true)
        }
    }
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] (result) in
            switch result {
            case .success(let messages):
                print("Success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("mesages are empty")
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
//                        self?.messagesCollectionView.scrollToBottom()
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
            case .failure(let error):
                print("failed to get messages with error :\(error)")
            }
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageID = createMessageID(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = self.selfSender else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
            // upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] (result) in
                
                switch result {
                case .success(let urlString):
                    //ready to send message
                    print("uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .photo((media)))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: self!.otherUserEmail, name: name, newMessage: message) { (success) in
                        if success {
                            print("Sent photo message")
                        } else {
                            print("failed to send photo message ")
                        }
                
                    }
                
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            
            //upload video
            
            StorageManager.shared.uploadMessageVideo(with: videoURL, fileName: fileName) { [weak self] (result) in
                
                switch result {
                case .success(let urlString):
                    //ready to send message
                    print("uploaded message video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeHolder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                    
                    let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .video((media)))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: self!.otherUserEmail, name: name, newMessage: message) { (success) in
                        if success {
                            print("Sent video message")
                        } else {
                            print("failed to send photo message ")
                        }
                
                    }
                
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        }
        
        
        //send message
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID() else {
            return
        }
        
        print("Sending:... \(text)")
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))

        //Send Message
        if isNewConversation {
            //create new conversatiaon in our db
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] (success) in
                if success {
                    print("message sent ")
                    self?.isNewConversation = false
                } else {
                    print("failed to send message")
                }
            }
        } else {
            
            //cont here
//            https://youtu.be/Q5tBgG2BvPc?list=PL5PR3UyfTWvdlk-Qi-dPtJmjTj-2YIMMf&t=1146
            // append to existing conversation data
            guard let conversationID = conversationID,
                  let name = self.title else {
                
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail , name: name, newMessage: message) { (success) in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        }
    }
    private func createMessageID() -> String? {
        //date, otherUserEmail, senderEmail, randomIng
       
        
        let dateString = Self.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)

        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            imageView.sd_setImage(with: imageURL, completed: nil)
        default:
            break
        }
    }
    
    
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        print(indexPath)
            
        let message = messages[indexPath.section]
        print(message.kind)
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoURL)
            
            present(vc, animated: true, completion: nil)
            
            
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
       
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        print(indexPath)
            
        let message = messages[indexPath.section]
        print(message.kind)
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageURL)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoURL)
            
            present(vc, animated: true, completion: nil)
            
            
        default:
            break
        }
    }
}
