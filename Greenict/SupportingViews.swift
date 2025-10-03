//
//  SupportingViews.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Charts

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var deviceManager: DeviceManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            DevicesListView()
                .tabItem {
                    Label("Devices", systemImage: "lightbulb.fill")
                }
                .tag(1)
            
            AutomationView()
                .tabItem {
                    Label("Automation", systemImage: "wand.and.stars")
                }
                .tag(2)
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(.green)
    }
}

// MARK: - Room Breakdown View
struct RoomBreakdownView: View {
    @EnvironmentObject var deviceManager: DeviceManager
    private let roomData = MockDataGenerator.generateRoomBreakdown()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Room-by-Room Usage")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(roomData) { room in
                HStack(spacing: 15) {
                    // Room Icon
                    Image(systemName: roomIcon(for: room.room))
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(room.room)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            Text("\(room.activeDevices)/\(room.deviceCount) active")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text("$\(String(format: "%.2f", room.cost))")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    // Usage Bar
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(String(format: "%.1f", room.usage)) kWh")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        ProgressView(value: room.percentage / 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: 80)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    private func roomIcon(for room: String) -> String {
        switch room {
        case "Living Room": return "sofa.fill"
        case "Kitchen": return "fork.knife"
        case "Bedroom": return "bed.double.fill"
        case "Bathroom": return "drop.fill"
        case "Office": return "desktopcomputer"
        case "Garage": return "car.fill"
        default: return "house.fill"
        }
    }
}

// MARK: - Cost Analysis Card
struct CostAnalysisCard: View {
    @EnvironmentObject var energyAnalytics: EnergyAnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Cost Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("This Month")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$127.43")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Projected")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$145.20")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("Savings")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$17.77")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right")
                            .font(.caption)
                        Text("12.2%")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Device Patterns Tab
struct DevicePatternsTab: View {
    let device: SmartDevice
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Usage Patterns")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Device Costs Tab
struct DeviceCostsTab: View {
    let device: SmartDevice
    @State private var selectedPeriod = CostPeriod.daily
    
    var body: some View {
        VStack(spacing: 20) {
            // Cost Breakdown
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Cost Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(CostPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                
                // Cost Stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    CostStatCard(
                        title: "Current Rate",
                        value: "$0.12/kWh",
                        icon: "bolt.circle.fill",
                        color: .orange
                    )
                    
                    CostStatCard(
                        title: selectedPeriod.title,
                        value: selectedPeriod.cost(for: device),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    CostStatCard(
                        title: "Peak Hours Cost",
                        value: "$\(String(format: "%.2f", device.estimatedDailyCost * 1.5))",
                        icon: "arrow.up.circle.fill",
                        color: .red
                    )
                    
                    CostStatCard(
                        title: "Off-Peak Savings",
                        value: "$\(String(format: "%.2f", device.estimatedDailyCost * 0.3))",
                        icon: "arrow.down.circle.fill",
                        color: .mint
                    )
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
        }
    }
}

// MARK: - Device Control Panel
struct DeviceControlPanel: View {
    let device: SmartDevice
    @Binding var showScheduler: Bool
    @EnvironmentObject var deviceManager: DeviceManager
    @State private var brightness: Double = 75
    @State private var temperature: Double = 22
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Controls")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Device-specific controls
            if device.category == .lighting {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Brightness: \(Int(brightness))%")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Slider(value: $brightness, in: 0...100, step: 5)
                        .accentColor(.yellow)
                }
            } else if device.category == .heating || device.category == .cooling {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Temperature: \(Int(temperature))°C")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Slider(value: $temperature, in: 16...30, step: 0.5)
                        .accentColor(device.category == .heating ? .orange : .blue)
                }
            }
            
            // Quick Actions
            HStack(spacing: 10) {
                ControlButton(
                    title: "Schedule",
                    icon: "clock.fill",
                    action: { showScheduler = true }
                )
                
                ControlButton(
                    title: "Timer",
                    icon: "timer",
                    action: { }
                )
                
                ControlButton(
                    title: "Scenes",
                    icon: "wand.and.stars",
                    action: { }
                )
                
                ControlButton(
                    title: "Share",
                    icon: "person.2.fill",
                    action: { }
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Device AI Recommendations
struct DeviceAIRecommendations: View {
    let device: SmartDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.green)
                Text("AI Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 10) {
                RecommendationRow(
                    icon: "moon.fill",
                    title: "Enable Sleep Mode",
                    subtitle: "Auto-off between 11 PM - 6 AM",
                    savings: "$3.20/mo"
                )
                
                RecommendationRow(
                    icon: "sensor.tag.radiowaves.forward",
                    title: "Add Motion Sensor",
                    subtitle: "Reduce usage by 40% in low-traffic areas",
                    savings: "$8.50/mo"
                )
                
                RecommendationRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Upgrade to Smart Model",
                    subtitle: "New model is 30% more efficient",
                    savings: "$12.00/mo"
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.1),
                    Color.green.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

// MARK: - AI Suggestions View
struct AISuggestionsView: View {
    @EnvironmentObject var aiOptimizer: AIEnergyOptimizer
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Optimization Score
                    Text("Optimization Score: \(aiOptimizer.optimizationScore)%")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // AI Insights
                    ForEach(aiOptimizer.insights, id: \.id) { insight in
                        Text(insight.message)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("AI Energy Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: Text("Profile Settings")) {
                        SettingsRow(icon: "person.fill", title: "Profile", color: .blue)
                    }
                    
                    NavigationLink(destination: Text("Voice Assistants")) {
                        SettingsRow(icon: "mic.fill", title: "Voice Assistants", color: .green)
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                    }
                }
                
                Section {
                    Button(action: { authViewModel.signOut() }) {
                        SettingsRow(icon: "arrow.right.square.fill", title: "Sign Out", color: .red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Automation View
struct AutomationView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Automation Center")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Automation")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Reports View
struct ReportsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Energy Reports")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Helper Components
struct ControlButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let savings: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(savings)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

struct CostStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 25)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Supporting Types
enum CostPeriod: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var title: String {
        switch self {
        case .daily: return "Daily Cost"
        case .weekly: return "Weekly Cost"
        case .monthly: return "Monthly Cost"
        case .yearly: return "Yearly Cost"
        }
    }
    
    func cost(for device: SmartDevice) -> String {
        switch self {
        case .daily:
            return "$\(String(format: "%.2f", device.estimatedDailyCost))"
        case .weekly:
            return "$\(String(format: "%.2f", device.estimatedDailyCost * 7))"
        case .monthly:
            return "$\(String(format: "%.2f", device.estimatedDailyCost * 30))"
        case .yearly:
            return "$\(String(format: "%.2f", device.estimatedDailyCost * 365))"
        }
    }
}

// Placeholder views
struct DeviceOverviewTab: View {
    let device: SmartDevice
    var body: some View {
        Text("Device Overview")
            .foregroundColor(.white)
    }
}

struct DeviceSchedulerView: View {
    let device: SmartDevice
    var body: some View {
        Text("Device Scheduler")
            .foregroundColor(.white)
    }
}

struct DeviceSettingsView: View {
    let device: SmartDevice
    var body: some View {
        Text("Device Settings")
            .foregroundColor(.white)
    }
}

struct AddDeviceView: View {
    var body: some View {
        Text("Add New Device")
            .foregroundColor(.white)
    }
}
