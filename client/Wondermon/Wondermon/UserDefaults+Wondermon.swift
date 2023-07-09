//
//  UserDefault.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import Foundation

extension UserDefaults {
    func store(user: User) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            UserDefaults.standard.set(data, forKey: "user")
            return true
        } catch {
            debugPrint(error)
            return false
        }
    }
}
