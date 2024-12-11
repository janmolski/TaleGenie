import SwiftUI

class AppEnvironment: ObservableObject {
    @Published var authManager: AuthenticationManager
    @Published var taleStore: TaleStore
    @Published var openAIService: OpenAIService
    
    static let shared = AppEnvironment()
    
    private init() {
        self.authManager = AuthenticationManager.shared
        self.taleStore = TaleStore()
        self.openAIService = OpenAIService()
    }
} 