import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("TaleGenie")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Create magical stories with AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            SignInWithAppleButton(
                onRequest: { request in
                    authManager.handleSignInWithAppleRequest(request)
                },
                onCompletion: { result in
                    authManager.handleSignInWithAppleCompletion(result)
                }
            )
            .frame(height: 50)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
} 