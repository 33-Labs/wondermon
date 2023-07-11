//
//  String+Wondermon.swift
//  Wondermon
//
//  Created by Cai Linfeng on 2023/7/9.
//

import Foundation

extension String {
    func isValidEmail() -> Bool {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: self.utf16.count)
            let matches = regex.matches(in: self, range: range)
            return !matches.isEmpty
        } catch {
            return false
        }
    }
    
    func isValidUsername() -> Bool {
        let pattern = "^(?!\\d)[a-zA-Z0-9]{4,15}$"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: self.utf16.count)
            let matches = regex.matches(in: self, range: range)
            return !matches.isEmpty
        } catch {
            return false
        }
    }
    
    func isValidPassword() -> Bool {
        return self.count > 5
    }
}
