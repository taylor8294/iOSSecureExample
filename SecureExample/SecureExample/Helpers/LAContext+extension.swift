import LocalAuthentication

extension LAContext {
    enum AuthType: Int {
        case none = 0 //LABiometryType.typeNone
        case touchID = 1 //LABiometryType.typeTouchID
        case faceID = 2 //LABiometryType.typeFaceID
        case passcode = 3
        case unknown = 4
    }
    
    var authType: AuthType {
        let context = LAContext()
        let hasAuthenticationBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        let hasAuthentication = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        if #available(iOS 11.0, *) {
            if hasAuthentication {
                if hasAuthenticationBiometrics {
                    switch context.biometryType {
                        case .none: return .passcode
                        case .faceID: return .faceID
                        case .touchID: return .touchID
                        @unknown default: return .unknown
                    }
                } else {
                    return .passcode
                }
            } else {
                return .none
            }
        } else {
            if hasAuthentication {
                if hasAuthenticationBiometrics {
                    return .touchID
                } else {
                    return .passcode
                }
            } else {
                return .none
            }
        }
    }
}
