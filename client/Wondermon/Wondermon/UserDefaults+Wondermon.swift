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
    
    func fetchUser() -> User? {
        if let data = UserDefaults.standard.data(forKey: "user") {
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(User.self, from: data)
                return user
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func deleteUser() {
        UserDefaults.standard.removeObject(forKey: "user")
    }
}
