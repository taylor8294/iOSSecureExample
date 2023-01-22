//
//  CommonCrypto+extension.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import Foundation
import CommonCrypto
import CryptoKit

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
        var saltData = Data()
        if let salt = salt {
            if salt.count < 8 {
                saltData.append(salt)
                saltData.append(getRandomBytes(8-salt.count)!)
            }
        } else {
            saltData = getRandomBytes(8)!
        }
        var derivedKeyData = Data(repeating: 0, count: keyByteCount)
        let derivedKeyDataCount = derivedKeyData.count
        
        let derivationStatus: OSStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            let derivedKeyRawBytes = derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress
            return saltData.withUnsafeBytes { saltBytes in
                let rawSaltBytes = saltBytes.bindMemory(to: UInt8.self).baseAddress
                return CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password,
                    passwordData.count,
                    rawSaltBytes,
                    saltData.count,
                    hash,
                    UInt32(rounds),
                    derivedKeyRawBytes,
                    derivedKeyDataCount
                )
            }
        }
        
        return derivationStatus == kCCSuccess ? derivedKeyData : nil
    }
    
    static func pbkdf2(
        password: String,
        salt: Data? = nil,
        keyByteCount: Int = 32,
        rounds: Int = 100_000,
        hash: CCPBKDFAlgorithm = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
    ) -> String? {
        if let data : Data = pbkdf2(password: password, salt: salt, keyByteCount: keyByteCount, rounds: rounds, hash: hash) {
            return data.hexEncodedString()
        }
        return nil
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
