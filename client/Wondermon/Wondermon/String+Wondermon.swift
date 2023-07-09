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
            print("Invalid regex pattern: \(error.localizedDescription)")
            return false
        }
    }
}