//
//  ContentView.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

//
//  ContentView.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var deviceManager = DeviceManager()
    @StateObject private var energyAnalytics = EnergyAnalyticsViewModel()
    @StateObject private var aiOptimizer = AIEnergyOptimizer()
    
    var body: some View {
        RootView()
            .environmentObject(authViewModel)
            .environmentObject(deviceManager)
            .environmentObject(energyAnalytics)
            .environmentObject(aiOptimizer)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
