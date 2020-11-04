//
//  ConversationsModels.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 04/11/2020.
//

import Foundation


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
