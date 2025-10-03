//
//  GreenictApp.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

@main
struct GreenictApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var deviceManager = DeviceManager()
    @StateObject private var energyAnalytics = EnergyAnalyticsViewModel()
    @StateObject private var aiOptimizer = AIEnergyOptimizer()
    
    init() {
        FirebaseApp.configure()
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(deviceManager)
                .environmentObject(energyAnalytics)
                .environmentObject(aiOptimizer)
                .preferredColorScheme(.dark)
        }
    }
    
    private func setupAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.systemGreen
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.systemGreen
        ]
    }
}

// Root View to handle authentication state
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            authViewModel.checkAuthStatus()
        }
    }
}
