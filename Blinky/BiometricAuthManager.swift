//
//  BiometricAuthManager.swift
//  Blinky
//
//  Created by Sebastián Vidal Aedo on 25-08-26.
//

import Foundation
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    private init() {}
    
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // .deviceOwnerAuthentication allows Touch ID, Apple Watch, or device passcode/password
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if let authError = authError {
                        print("Authentication failed: \(authError.localizedDescription)")
                    }
                    completion(success)
                }
            }
        } else {
            // Fallback or policy unavailable
            print("Device owner authentication not available: \(error?.localizedDescription ?? "unknown error")")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
