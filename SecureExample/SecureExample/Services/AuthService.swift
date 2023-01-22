//
//  LoginViewModel.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import SwiftUI

class AuthService : ObservableObject {
    private let authenticator = OAuth2PKCEAuthenticator(domain: "192.168.1.117:3000", clientId: "my_app")
    private var accessTokenResponse : AccessTokenResponse?
    private var accessTokenResponseDate : Date?
    public var accessToken: String? {
        accessTokenResponse?.access_token
    }
    public var refreshToken: String? {
        accessTokenResponse?.refresh_token
    }
    
    public func authenticate(username: String, password:String) async -> Result<AccessTokenResponse, OAuth2PKCEAuthenticatorError> {
        await withCheckedContinuation { continuation in
            authenticator.authenticate(username: username, password: password){ result in
                if case .success(let resp) = result {
                    self.accessTokenResponse = resp
                    self.accessTokenResponseDate = Date.now
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func getTokenInfo(accessToken:String? = nil) async -> Result<TokenInfoResponse, OAuth2PKCEAuthenticatorError> {
        var token = accessToken
        if token == nil {
            token = accessTokenResponse?.access_token
        }
        if let token = token {
            return await withCheckedContinuation { continuation in
                authenticator.checkToken(accessToken: token){ result in
                    continuation.resume(returning: result)
                }
            }
        }
        return Result.failure(OAuth2PKCEAuthenticatorError.tokenResponseInvalidData("No token passed"))
    }
    
    public func isTokenValid(accessToken:String? = nil) async -> Bool {
        let result = await getTokenInfo(accessToken: accessToken)
        switch result {
        case .success(let resp):
            return resp.valid
        case .failure:
            return false
        }
    }
    
    public func expiresIn(accessToken: String?) async -> Int {
        if let accessToken = accessToken {
            let result = await getTokenInfo(accessToken: accessToken)
            switch result {
            case .success(let resp):
                return resp.valid ? resp.expires_in : -1
            case .failure:
                return -1
            }
        }
        return expiresIn()
    }
    
    public func expiresIn() -> Int {
        if let accessTokenResponse = accessTokenResponse, let accessTokenResponseDate = accessTokenResponseDate {
            return max(accessTokenResponse.expires_in - Int(Date.now - accessTokenResponseDate), -1)
        }
        return -1
    }
    
    public func expiresAt(accessToken: String?) async -> Date {
        let calendar = Calendar.current
        let expiresIn = await expiresIn(accessToken: accessToken)
        return calendar.date(byAdding: .second, value: expiresIn, to: Date.now)!
    }
    
    public func expiresAt() -> Date {
        let calendar = Calendar.current
        let expiresIn = expiresIn()
        return calendar.date(byAdding: .second, value: expiresIn, to: Date.now)!
    }
    
    public func saveTokenToKeychain(accessTokenResponse: AccessTokenResponse? = nil, with applicationPassword: String? = nil) -> Bool {
        var resp = accessTokenResponse
        if resp == nil {
            resp = self.accessTokenResponse
        }
        if let resp = resp {
            if let applicationPassword = applicationPassword {
                return KeychainWrapper.standard.set(resp, forKey: "access_token_app_password", withApplicationPassword: applicationPassword)
            } else {
                return KeychainWrapper.standard.set(resp, forKey: "access_token", requireBiometrics: true)
            }
        }
        return false
    }
    
    public func loadTokenFromKeychain(with applicationPassword: String? = nil) -> Bool {
        let resp : AccessTokenResponse?
        if let applicationPassword = applicationPassword {
            resp = KeychainWrapper.standard.object(forKey: "access_token_app_password", withApplicationPassword: applicationPassword)
        } else {
            resp = KeychainWrapper.standard.object(forKey: "access_token", requireBiometrics: true)
        }
        if let resp = resp {
            self.accessTokenResponse = resp
            return true
        }
        return false
    }
    
    public func logout(clearKeychain : Bool = true){
        if clearKeychain {
            KeychainWrapper.standard.removeAllKeys()
        }
        accessTokenResponse = nil
        accessTokenResponseDate = nil
    }
}

// Add injection

private struct AuthServiceKey: InjectionKey {
    static var currentValue = AuthService()
}

extension InjectedValues {
    var authService: AuthService {
        get { Self[AuthServiceKey.self] }
        set { Self[AuthServiceKey.self] = newValue }
    }
}
