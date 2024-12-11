//
//  TaleGenieApp.swift
//  TaleGenie
//
//  Created by Jan Molski on 10/12/2024.
//

import SwiftUI

@main
struct TaleGenieApp: App {
    @StateObject private var environment = AppEnvironment.shared
    
    var body: some Scene {
        WindowGroup {
            if environment.authManager.isAuthenticated {
                MainContentView()
                    .environmentObject(environment.authManager)
                    .environmentObject(environment.taleStore)
                    .environmentObject(environment.openAIService)
            } else {
                LoginView()
                    .environmentObject(environment.authManager)
            }
        }
    }
}
