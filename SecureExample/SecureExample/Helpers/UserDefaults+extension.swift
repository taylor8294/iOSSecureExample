import SwiftUI

extension UserDefaults {
    
    enum Key : String {
        case firstOpenDate = "AppDelegate.firstOpenDate"
        case lastOpenDate = "AppDelegate.lastOpenDate"
        case thisOpenDate = "AppDelegate.thisOpenDate"
        case totalOpens = "AppDelegate.totalOpens"
    }
    
    func get<T>(forKey key: String) -> T? {
        switch T.self {
        case is String.Type:
            return self.string(forKey: key) as? T
        case is Int.Type:
            return self.integer(forKey: key) as? T
        case is Float.Type:
            return self.float(forKey: key) as? T
        case is Double.Type:
            return self.double(forKey: key) as? T
        case is Bool.Type:
            return self.bool(forKey: key) as? T
        case is [String].Type:
            return self.stringArray(forKey: key) as? T
        case is [Any].Type:
            return self.array(forKey: key) as? T
        case is [String : Any].Type:
            return self.dictionary(forKey: key) as? T
        case is URL.Type:
            return self.url(forKey: key) as? T
        default:
            return self.object(forKey: key) as? T
        }
    }
    
    func set<T>(_ value: T?, forKey key: String) {
        switch T.self {
        case is String.Type:
            if let v : String = value as? String {
                self.set(v, forKey: key)
                return
            }
        case is Int.Type:
            if let v : Int = value as? Int {
                self.set(v, forKey: key)
                return
            }
        case is Float.Type:
            if let v : Float = value as? Float {
                self.set(v, forKey: key)
                return
            }
        case is Double.Type:
            if let v : Double = value as? Double {
                self.set(v, forKey: key)
                return
            }
        case is Bool.Type:
            if let v : Bool = value as? Bool {
                self.set(v, forKey: key)
                return
            }
        case is URL.Type:
            if let v : URL = value as? URL {
                self.set(v, forKey: key)
                return
            }
        default:
            if let val = value {
                self.set(val as Any?, forKey: key)
            } else {
                self.set(nil as Any?, forKey: key)
            }
        }
    }
    
    func get<T>(forKey key: Key) -> T? {
        return get(forKey: key.rawValue)
    }
    
    func set<T>(_ value: T?, forKey key: Key) {
        return set(value, forKey: key.rawValue)
    }
    
    static func trackOpen(){
        let now: Date = Date.now
        let firstOpenDate : Date? = standard.get(forKey: .firstOpenDate)
        if firstOpenDate == nil {
            standard.set(now, forKey: .firstOpenDate)
            standard.set(now, forKey: .lastOpenDate)
            standard.set(1, forKey: .totalOpens)
        } else {
            let lastOpenDate: Date? = standard.get(forKey: .thisOpenDate)
            if let lastOpenDate = lastOpenDate {
                standard.set(lastOpenDate, forKey: .lastOpenDate)
            } else {
                standard.set(firstOpenDate, forKey: .lastOpenDate)
            }
            let totalOpens : Int = max(standard.get(forKey: .totalOpens) ?? 0,0) + 1
            standard.set(totalOpens, forKey: .totalOpens)
        }
        standard.set(now, forKey: .thisOpenDate)
    }
}
