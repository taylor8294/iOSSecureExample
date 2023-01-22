//
//  PasscodeViewModel.swift
//  SecureExample
//
//  Created by Alex T on 30/12/2022.
//

import SwiftUI

class PasscodeViewModel : ObservableObject {
    @Injected(\.authService) var authService: AuthService
    @Published var pin1Focused = false
    @Published var pin2Focused = false
    @Published var pin1Input = "" {
        didSet {
            if pin1Input.count > 5 {
                withAnimation {
                    pin1Done = true
                }
                pin1Focused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.pin2Focused = true
                }
            }
        }
    }
    @Published var pin2Input = "" {
        didSet {
            if pin2Input.count > 5 {
                withAnimation {
                    pin2Done = true
                }
                pin2Focused = false
                var succ = false
                if pin1Input.count == 6 && pin1Input == pin2Input {
                    KeychainWrapper.standard.removeAllKeys()
                    let udid = UIDevice.current.identifierForVendor?.uuidString ?? ""
                    succ = authService.saveTokenToKeychain(
                        with:CryptoHelper.pbkdf2(
                            password: [String(pin1Input.prefix(3)),udid,String(pin1Input.suffix(3))].joined(separator: "_")
                        )
                    )
                    succ = succ && authService.saveTokenToKeychain()
                }
                if succ {
                    guard let dismiss = dismiss else { return }
                    dismiss()
                } else {
                    self.pin2Input = ""
                    self.pin1Input = ""
                    withAnimation {
                        pin1Done = false
                        pin2Done = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.pin1Focused = true
                    }
                }
            }
        }
    }
    @Published var pin1Done : Bool = false
    @Published var pin2Done : Bool = false
    func onAppear(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.pin1Focused = true
        }
    }
    var dismiss : DismissAction? = nil
    
}
