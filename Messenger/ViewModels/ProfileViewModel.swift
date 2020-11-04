//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Juan Manuel Tome on 04/11/2020.
//

import Foundation


enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
