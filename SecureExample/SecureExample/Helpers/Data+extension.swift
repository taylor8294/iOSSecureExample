//
//  Data+extension.swift
//  SecureExample
//
//  hexEncodedString from https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
//

import Foundation

extension Data {
    init?(hexEncoded: String) {
        let len = hexEncoded.count / 2
        var data = Data(capacity: len)
        var i = hexEncoded.startIndex
        for _ in 0..<len {
            let j = hexEncoded.index(i, offsetBy: 2)
            let bytes = hexEncoded[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
