//
//  ChatModels.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 04/11/2020.
//

import Foundation
import CoreLocation
import MessageKit  

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
