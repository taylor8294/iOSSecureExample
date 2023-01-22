//
//  CommonCrypto+extension.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import Foundation
import CommonCrypto
import CryptoKit

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


public class CryptoHelper {
    
    static func getRandomBytes(_ count: Int = 32) -> Data? {
        var keyData = Data(count: count)
        let result = keyData.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, count, mutableBytes.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            return nil
        }
    }
    
    static func pbkdf2(
        password: String,
        salt: Data? = nil,
        keyByteCount: Int = 32,
        rounds: Int = 100000,
        hash: CCPBKDFAlgorithm = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
    ) -> Data? {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        let s = salt == nil ? getRandomBytes(8)! : salt!
        var derivedKeyData = Data(repeating: 0, count: keyByteCount)
        let derivedCount = derivedKeyData.count
        
        let derivationStatus: OSStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            let derivedKeyRawBytes = derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress
            return s.withUnsafeBytes { saltBytes in
                let rawBytes = saltBytes.bindMemory(to: UInt8.self).baseAddress
                return CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password,
                    passwordData.count,
                    rawBytes,
                    s.count,
                    hash,
                    UInt32(rounds),
                    derivedKeyRawBytes,
                    derivedCount
                )
            }
        }
        
        return derivationStatus == kCCSuccess ? derivedKeyData : nil
    }
    
    static func encrypt(plaintext: Data, with keyData: Data) -> AES.GCM.SealedBox? {
        let key = SymmetricKey(data: keyData)
        let nonce = getRandomBytes(12)
        return try? AES.GCM.seal(plaintext, using: key, nonce: AES.GCM.Nonce(data:nonce!))
    }
    
    static func encrypt(plaintext: String, with keyData: Data) -> String? {
        guard let plainData = plaintext.data(using: .utf8) else { return nil }
        if let sealedData = encrypt(plaintext: plainData, with: keyData){
            return sealedData.combined?.hexEncodedString()
        }
        return nil
    }
    
    static func decrypt(ciphertext: Data, nonce: AES.GCM.Nonce, tag:Data, with keyData: Data) -> Data? {
        let sealedBox = try? AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: ciphertext,
            tag: tag
        )
        if let sealedBox = sealedBox {
            return try? AES.GCM.open(sealedBox, using: SymmetricKey(data: keyData))
        }
        return nil
    }
    
    static func decrypt(ciphertext: Data, with keyData: Data) -> Data? {
        let key = SymmetricKey(data: keyData)
        let sealedBox = try? AES.GCM.SealedBox(combined: ciphertext)
        if let sealedBox = sealedBox {
            return try? AES.GCM.open(sealedBox, using: key)
        }
        return nil
    }
    
    static func decrypt(ciphertext: String, with keyData: Data) -> String? {
        guard let combinedData = Data(hexEncoded: ciphertext) else { return nil }
        let decryptedData = decrypt(ciphertext: combinedData, with: keyData)
        if let decryptedData = decryptedData {
            return String(decoding: decryptedData, as: UTF8.self)
        }
        return nil
    }
    
    static func test(){
        let password     = "secret"
        let derivedKey : Data = pbkdf2(password:password, keyByteCount:32)!
        print("derivedKey (SHA256): \(derivedKey.hexEncodedString())")
        
        let plaintext = "This is a plain text"
        let encryptedContent = encrypt(plaintext: plaintext, with: derivedKey)
        print("Encrypted: \(encryptedContent ?? "")")
        
        let decryptedContent = decrypt(ciphertext: encryptedContent ?? "", with: derivedKey)
        print("Decrypted: \(decryptedContent ?? "")")
    }
}

CryptoHelper.test()
