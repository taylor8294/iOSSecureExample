//
//  String+extension.swift
//  SecureExample
//
//  Created by Alex T on 01/01/2023.
//

import Foundation

extension String {
    func chunked(into size: Int) -> [Substring] {
        return stride(from: 0, to: count, by: size).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(self.startIndex, offsetBy: min($0+size,self.count))
            return self[start ..< end]
        }
    }
}
