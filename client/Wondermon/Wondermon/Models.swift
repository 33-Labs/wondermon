//
//  Flovatar.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/8.
//

import Foundation

struct FlowAccount: Codable {
    let address: String
}

struct User: Codable {
    let name: String
    let email: String
    let accessToken: String
    let flowAccount: FlowAccount?
}

struct AiMessage: Codable {
    let message: String
    let txid: String?
}

struct UserResponse: Codable {
    let status: Bool
    let message: String
    let data: User?
}

struct AiMessageResponse: Codable {
    let status: Bool
    let message: String
    let data: AiMessage?
}
