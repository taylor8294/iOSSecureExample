//
//  LoginViewModel.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import SwiftUI

class LoginViewModel : ObservableObject {
    @Injected(\.authService) var authService: AuthService
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var usernameInput: String = "alex"
    @Published var passwordInput: String = "test123"
    @Published var passwordFocussed: Bool = false
    @Published var showingPin = false
    
    func onAppear(){
        if authService.loadTokenFromKeychain() {
            alertMessage = "Loaded access_token from keychain: \(authService.accessToken!)"
        } else {
            alertMessage = "No access_token currently stored, please log in"
        }
        showAlert = true
    }
    
    func login() {
        Task {
            let result = await authService.authenticate(username: usernameInput, password: passwordInput)
            switch result {
            case .success:
                // alertMessage = "Successful login, now opening pin prompt"
                DispatchQueue.main.async {
                    self.passwordFocussed = false
                    self.showingPin = true
                }
            case .failure(let error):
                self.alertMessage = error.localizedDescription
                DispatchQueue.main.async { self.showAlert = true }
            }
        }
    }
    
    func logout() {
        authService.logout()
        alertMessage = "Logged out (removed all keys from keychain)"
        showAlert = true
    }
}
