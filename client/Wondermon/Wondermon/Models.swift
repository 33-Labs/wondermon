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

struct Message: Codable {
    let name: String
    let text: String
    
    func toJsonString() -> String {
        let dictionary: [String: String] = ["name": self.name, "text": self.text]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                return jsonString
            }
        } catch {
            print("Error converting dictionary to JSON: \(error.localizedDescription)")
        }
        
        return ""
    }
}

struct AiMessage: Codable {
    let message: String
    let txid: String?
}

struct UserResponse: Codable {
    let status: UInt8
    let message: String
    let data: User?
}

struct AiMessageResponse: Codable {
    let status: UInt8
    let message: String
    let data: AiMessage?
}

struct HTTPFile: Codable {
    let url: String
}

struct FlobitDisplay: Codable {
    let name: String
    let description: String
    let thumbnail: HTTPFile
}

struct Flobit: Codable {
    let id: UInt64
    let display: FlobitDisplay
}

struct Flovatar: Codable {
    let id: UInt64
}

struct Contact: Codable {
    let id: UInt64
    let name: String
    let address: String
}

struct ContactResponse: Codable {
    let status: UInt8
    let message: String
    let data: Contact?
}

struct ContactsResponse: Codable {
    let status: UInt8
    let message: String
    let data: [Contact]
}

struct BaseResponse: Codable {
    let status: UInt8
    let message: String
}


