//
//  KeychainView.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import SwiftUI

struct KeychainView: View {
    @State var alertMessage = ""
    @State var isShowingAlert = false
    
    var body: some View {
        VStack(spacing: 64) {
            Button("Set password"){
                NSLog("HELLOWORLD Calling set string")
                let succ = KeychainWrapper.standard.set("test123", forKey: "user_password", withApplicationPassword: "app_password")
                alertMessage = succ ? "Successfully added to keychain" : "Failed to add to keychain"
                isShowingAlert = true
            }
            .alert("Result", isPresented: $isShowingAlert){
                
            } message: {
                Text(alertMessage)
            }
            Button("Get password"){
                NSLog("HELLOWORLD Calling get string")
                let pass = KeychainWrapper.standard.string(forKey: "user_password", withApplicationPassword: "app_password")
                if let pass = pass {
                    alertMessage = "Success! Password is \(pass)"
                } else {
                    alertMessage = "Fail! Password is \(pass == nil ? "nil" : "\(pass!.count)")"
                }
                isShowingAlert = true
            }
            .alert("Result", isPresented: $isShowingAlert){
                
            } message: {
                Text(alertMessage)
            }
            Button("Remove password"){
                let succ = KeychainWrapper.standard.removeAllKeys()
                alertMessage = succ ? "Successfully remove all keys from keychain" : "Failed to remove keys from keychain"
                isShowingAlert = true
            }
            .alert("Result", isPresented: $isShowingAlert){
                
            } message: {
                Text(alertMessage)
            }
        }
    }
}

struct KeychainView_Previews: PreviewProvider {
    static var previews: some View {
        KeychainView()
    }
}
