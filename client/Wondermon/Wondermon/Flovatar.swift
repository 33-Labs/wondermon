//
//  Flovatar.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/8.
//

import Foundation

struct FlovatarData: Codable {
    let id: UInt64
    let name: String
}

struct User: Codable {
    let balance: Double
    let address: String
    let name: String
}
