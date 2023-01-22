//
//  OAuth2PKCEAuthenticator.swift
//  AppUsingPKCE
//
//  Orginal created by Eidinger, Marco on 12/16/21.
//  Edited for SecureExample by taylor8294.
//

import AuthenticationServices
import CommonCrypto
import Foundation

public enum OAuth2PKCEAuthenticatorError: LocalizedError {
    case authRequestFailed(Error)
    case authorizeResponseNoData
    case authorizeResponseInvalidData(String)
    case tokenRequestFailed(Error)
    case tokenResponseNoData
    case tokenResponseInvalidData(String)

    var localizedDescription: String {
        switch self {
        case .authRequestFailed(let error):
            return "authorization request failed: \(error.localizedDescription)"
        case .authorizeResponseNoData:
            return "no data received as part of authorization response"
        case .authorizeResponseInvalidData(let reason):
            return "invalid data received as part of authorization response: \(reason)"
        case .tokenRequestFailed(let error):
            return "token request failed: \(error.localizedDescription)"
        case .tokenResponseNoData:
            return "no data received as part of token response"
        case .tokenResponseInvalidData(let reason):
            return "invalid data received as part of token response: \(reason)"
        }
    }
}

public struct AuthCodeResponse: Codable {
    public var code: String
    public var state: String
}

public struct AccessTokenResponse: Codable {
    public var access_token: String
    public var refresh_token: String
    public var expires_in: Int
}

public struct TokenInfoResponse: Codable {
    public var valid: Bool
    public var client_id: String?
    public var scope: String?
    public var expires_in: Int
}

public class OAuth2PKCEAuthenticator: NSObject {
    
    let domain : String
    let authorizePath : String = "/oauth2/authorize"
    let tokenPath : String = "/oauth2/token"
    let tokenInfoPath : String = "/oauth2/tokenInfo"
    let clientId : String
    
    init(domain:String, clientId: String) {
        self.domain = domain
        self.clientId = clientId
        super.init()
    }

    public func authenticate(username: String, password: String, completion: @escaping (Result<AccessTokenResponse, OAuth2PKCEAuthenticatorError>) -> Void) {
        // 1. creates a cryptographically-random code_verifier
        let codeVerifier = self.createCodeVerifier()
        // 2. and from this generates a code_challenge
        let codeChallenge = self.codeChallenge(for: codeVerifier)
        
        getAuthCode(username: username, password: password, codeChallenge: codeChallenge){ res in
            switch res {
            case .success(let authResp):
                self.getAccessToken(authCode: authResp.code, codeVerifier: codeVerifier){ res2 in
                    switch res2 {
                    case .success(let tokenResp):
                        completion(.success(tokenResp))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func checkToken(accessToken: String, completion: @escaping (Result<TokenInfoResponse, OAuth2PKCEAuthenticatorError>) -> Void){
        getTokenInfo(accessToken: accessToken){ res in
            switch res {
            case .success(let tokenInfoResp):
                completion(.success(tokenInfoResp))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func createCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(bytes: buffer)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func codeChallenge(for verifier: String) -> String {
        // Dependency: Apple Common Crypto library
        // http://opensource.apple.com//source/CommonCrypto
        guard let data = verifier.data(using: .utf8) else { fatalError() }
        var buffer = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes{
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
        }
        let hash = Data(buffer)
        return hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func getAuthCode(username: String, password: String, codeChallenge: String, completion: @escaping (Result<AuthCodeResponse, OAuth2PKCEAuthenticatorError>) -> Void) {
        
        // generate random state string
        let state = UUID().uuidString
        
        let request = createAuthRequest(
            username: username,
            password: password,
            codeChallenge: codeChallenge,
            state: state
        )

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(.failure(OAuth2PKCEAuthenticatorError.authRequestFailed(error!)))
                return
            } else {
                guard let data  = data else {
                    completion(.failure(OAuth2PKCEAuthenticatorError.authorizeResponseNoData))
                    return
                }
                do {
                    let authResponse = try JSONDecoder().decode(AuthCodeResponse.self, from: data)
                    if authResponse.state == state {
                        completion(.success(authResponse))
                    } else {
                        completion(.failure(.authorizeResponseInvalidData("State mismatch")))
                    }
                } catch {
                    let reason = String(data: data, encoding: .utf8) ?? "Unknown"
                    completion(.failure(.authorizeResponseInvalidData(reason)))
                }
            }
        })
        dataTask.resume()
    }
    
    private func getAccessToken(authCode: String, codeVerifier: String, completion: @escaping (Result<AccessTokenResponse, OAuth2PKCEAuthenticatorError>) -> Void) {

        let request = createTokenRequest(
            code: authCode,
            codeVerifier: codeVerifier
        )

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(.failure(OAuth2PKCEAuthenticatorError.tokenRequestFailed(error!)))
                return
            } else {
                guard let data  = data else {
                    completion(.failure(OAuth2PKCEAuthenticatorError.tokenResponseNoData))
                    return
                }
                do {
                    let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: data)
                    completion(.success(tokenResponse))
                } catch {
                    let reason = String(data: data, encoding: .utf8) ?? "Unknown"
                    completion(.failure(OAuth2PKCEAuthenticatorError.tokenResponseInvalidData(reason)))
                }
            }
        })
        dataTask.resume()
    }
    
    private func getTokenInfo(accessToken: String, completion: @escaping (Result<TokenInfoResponse, OAuth2PKCEAuthenticatorError>) -> Void) {

        let request = createTokenInfoRequest(accessToken: accessToken)

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion(.failure(OAuth2PKCEAuthenticatorError.tokenRequestFailed(error!)))
                return
            } else {
                guard let data  = data else {
                    completion(.failure(OAuth2PKCEAuthenticatorError.tokenResponseNoData))
                    return
                }
                do {
                    let tokenInfoResponse = try JSONDecoder().decode(TokenInfoResponse.self, from: data)
                    completion(.success(tokenInfoResponse))
                } catch {
                    let reason = String(data: data, encoding: .utf8) ?? "Unknown"
                    completion(.failure(OAuth2PKCEAuthenticatorError.tokenResponseInvalidData(reason)))
                }
            }
        })
        dataTask.resume()
    }
    
    private func createAuthRequest(username: String, password: String, codeChallenge: String, state: String) -> URLRequest {
        let request = NSMutableURLRequest(
            url: NSURL(string: "http://\(self.domain)\(self.authorizePath)")! as URL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 10.0
        )
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        request.httpBody = NSMutableData(data: "response_type=code&client_id=\(clientId)&username=\(username)&password=\(password)&code_challenge=\(codeChallenge)&state=\(state)".data(using: String.Encoding.utf8)!) as Data
        return request as URLRequest
    }
    
    private func createTokenRequest(code: String, codeVerifier: String) -> URLRequest {
        let request = NSMutableURLRequest(url: NSURL(string: "http://\(self.domain)\(self.tokenPath)")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        request.httpBody = NSMutableData(data: "grant_type=authorization_code&client_id=\(clientId)&code=\(code)&code_verifier=\(codeVerifier)".data(using: String.Encoding.utf8)!) as Data
        return request as URLRequest
    }
    
    private func createTokenInfoRequest(accessToken: String) -> URLRequest {
        let request = NSMutableURLRequest(url: NSURL(string: "http://\(self.domain)\(self.tokenInfoPath)")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        request.httpBody = NSMutableData(data: "access_token=\(accessToken)".data(using: String.Encoding.utf8)!) as Data
        return request as URLRequest
    }
    
}

fileprivate extension URL {
    func getQueryStringParameter(_ parameter: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == parameter })?.value
    }
}
