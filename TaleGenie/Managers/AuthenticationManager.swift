import Foundation
import AuthenticationServices
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userID: String?
    @Published var userName: String?
    
    static let shared = AuthenticationManager()
    
    private init() {
        // Check for existing credentials
        checkExistingCredentials()
    }
    
    private func checkExistingCredentials() {
        if let userID = UserDefaults.standard.string(forKey: "userID") {
            self.userID = userID
            self.isAuthenticated = true
        }
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }
            
            let userID = appleIDCredential.user
            let firstName = appleIDCredential.fullName?.givenName ?? ""
            
            // Store credentials
            UserDefaults.standard.set(userID, forKey: "userID")
            UserDefaults.standard.set(firstName, forKey: "userName")
            
            DispatchQueue.main.async {
                self.userID = userID
                self.userName = firstName
                self.isAuthenticated = true
            }
            
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "userID")
        UserDefaults.standard.removeObject(forKey: "userName")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userID = nil
            self.userName = nil
        }
    }
} 