//
//  UserDefault.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import Foundation

extension UserDefaults {
    func fetchMessages() -> [Message] {
        if let data = UserDefaults.standard.data(forKey: "messages") {
            do {
                let decoder = JSONDecoder()
                let notes = try decoder.decode([Message].self, from: data)
                return notes
            } catch {
                return []
            }
        } else {
            return []
        }
    }
    
    func store(message: Message) -> Bool {
        var messages = fetchMessages()
        messages.append(message)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: "messages")
            UserDefaults.standard.synchronize()
            return true
        } catch {
            debugPrint("Unable to Encode Array of Messages (\(error))")
            return false
        }
    }
    
    func deleteMessages() {
        UserDefaults.standard.removeObject(forKey: "messages")
        UserDefaults.standard.synchronize()
    }
    
    func store(user: User) -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            UserDefaults.standard.set(data, forKey: "user")
            UserDefaults.standard.synchronize()
            return true
        } catch {
            debugPrint("Unable to Encode Array of User (\(error))")
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
        UserDefaults.standard.synchronize()
    }
}
