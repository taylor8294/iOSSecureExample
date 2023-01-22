//
//  PasscodeView.swift
//  SecureExample
//
//  Created by Alex T on 29/12/2022.
//

import SwiftUI

struct PasscodeView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm = PasscodeViewModel()
    @FocusState var pin1Focused: Bool
    @FocusState var pin2Focused: Bool
    
    var body : some View {
        
        VStack(alignment: .leading) {
            Text("Please enter your pin code")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.top, 70)
                .padding(.bottom, 20)
            
            Text("This six-digit PIN will be used to authenticate you when biometrics isn't available.")
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)
            
            SecureField("PIN", text: $vm.pin1Input)
                .keyboardType(.numberPad)
                .padding()
                .background(Color("TextFieldColor"))
                .cornerRadius(5.0)
                .shadow(color: Color("LightShadow"), radius: 8, x: -8, y: -8)
                .shadow(color: Color("DarkShadow"), radius: 8, x: 8, y: 8)
                .border(.black)
                .focused($pin1Focused)
                .onChange(of: vm.pin1Focused) {
                    pin1Focused = $0
                }
                .onChange(of: pin1Focused) {
                    vm.pin1Focused = $0
                }
                .disabled(vm.pin1Done)
            
            if vm.pin1Done {
                SecureField("PIN2", text: $vm.pin2Input)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color("TextFieldColor"))
                    .cornerRadius(5.0)
                    .shadow(color: Color("LightShadow"), radius: 8, x: -8, y: -8)
                    .shadow(color: Color("DarkShadow"), radius: 8, x: 8, y: 8)
                    .border(.black)
                    .focused($pin2Focused)
                    .onChange(of: vm.pin2Focused) {
                        pin2Focused = $0
                    }
                    .onChange(of: pin2Focused) {
                        vm.pin2Focused = $0
                    }
                    .disabled(vm.pin2Done)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear{
            vm.dismiss = dismiss
            vm.onAppear()
        }
    }
    
}

struct PasscodeView_Previews: PreviewProvider {
    static var previews: some View {
        PasscodeView()
    }
}
