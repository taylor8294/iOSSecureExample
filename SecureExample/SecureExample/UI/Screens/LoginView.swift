//
//  LoginView.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject private var vm = LoginViewModel()
    @FocusState var passwordFocussed: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Username", text: $vm.usernameInput)
                    .autocapitalization(.none)
                SecureField("Password", text: $vm.passwordInput)
                    .focused($passwordFocussed)
                    .onChange(of: vm.passwordFocussed) {
                        passwordFocussed = $0
                    }
                    .onChange(of: passwordFocussed) {
                        vm.passwordFocussed = $0
                    }
                Button("Login", action: vm.login)
            }
            Section {
                Button("Show access token"){
                    NSLog("HELLOWORLD in access_token button press")
                    NSLog("HELLOWORLD vm.showAlert is \(vm.showAlert)")
                    vm.alertMessage = "Access token is: \(vm.authService.accessToken ?? "")"
                    vm.showAlert = true
                    NSLog("HELLOWORLD vm.showAlert is now \(vm.showAlert)")
                    NSLog("HELLOWORLD access_token button press end")
                }
                Button("Show refresh token"){
                    vm.alertMessage = "Refresh token is: \(vm.authService.refreshToken ?? "")"
                    vm.showAlert = true
                }
                Button("Remove saved credentials", action: vm.logout)
            }
        }
        .onAppear(perform:vm.onAppear)
        .alert("Login result", isPresented: $vm.showAlert, actions: {
            Button("OK"){}
        }, message: {
            Text(vm.alertMessage)
        })
        .fullScreenCover(isPresented: $vm.showingPin){
            PasscodeView()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
