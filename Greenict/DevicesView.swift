//
//  DevicesView.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Charts

// MARK: - Devices List View
struct DevicesListView: View {
    @EnvironmentObject var deviceManager: DeviceManager
    @State private var searchText = ""
    @State private var selectedCategory: DeviceCategory = .all
    @State private var showAddDevice = false
    @State private var sortBy: SortOption = .usage
    
    var filteredDevices: [SmartDevice] {
        let categoryFiltered = selectedCategory == .all ?
            deviceManager.devices :
            deviceManager.devices.filter { $0.category == selectedCategory }
        
        let searchFiltered = searchText.isEmpty ?
            categoryFiltered :
            categoryFiltered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        return searchFiltered.sorted { device1, device2 in
            switch sortBy {
            case .name:
                return device1.name < device2.name
            case .usage:
                return device1.currentUsage > device2.currentUsage
            case .room:
                return device1.room < device2.room
            case .status:
                return device1.isOn && !device2.isOn
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 15) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search devices...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    Button(action: { showAddDevice = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(DeviceCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                }
                
                // Sort Options
                HStack {
                    Text("\(filteredDevices.count) Devices")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortBy = option }) {
                                Label(option.rawValue, systemImage: option.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Sort by \(sortBy.rawValue)")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color.black)
            
            // Devices List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDevices) { device in
                        NavigationLink(destination: DeviceDetailView(device: device)) {
                            DeviceRowView(device: device)
                                .environmentObject(deviceManager)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.black)
        .navigationTitle("All Devices")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddDevice) {
            AddDeviceView()
                .environmentObject(deviceManager)
        }
    }
}

// MARK: - Device Row View
struct DeviceRowView: View {
    let device: SmartDevice
    @EnvironmentObject var deviceManager: DeviceManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Device Icon
                ZStack {
                    Circle()
                        .fill(device.isOn ? device.category.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: device.icon)
                        .font(.title2)
                        .foregroundColor(device.isOn ? device.category.color : .gray)
                }
                
                // Device Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        Label(device.room, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if device.isOn {
                            Label("\(String(format: "%.1f", device.currentUsage))W", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 8) {
                    Toggle("", isOn: Binding(
                        get: { device.isOn },
                        set: { _ in deviceManager.toggleDevice(device) }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .labelsHidden()
                    
                    if device.isOn {
                        Text("$\(String(format: "%.2f", device.estimatedDailyCost))/day")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded Quick Stats
            if isExpanded {
                HStack(spacing: 20) {
                    QuickStat(label: "Today", value: "\(String(format: "%.2f", device.todayUsage)) kWh")
                    QuickStat(label: "This Week", value: "\(String(format: "%.1f", device.weekUsage)) kWh")
                    QuickStat(label: "Efficiency", value: "\(device.efficiencyRating)%")
                }
                .padding()
                .background(Color.white.opacity(0.02))
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Device Detail View (Individual Analytics)
struct DeviceDetailView: View {
    let device: SmartDevice
    @EnvironmentObject var deviceManager: DeviceManager
    @EnvironmentObject var energyAnalytics: EnergyAnalyticsViewModel
    @State private var selectedTab = 0
    @State private var showScheduler = false
    @State private var showSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Device Header Card
                DeviceHeaderCard(device: device)
                    .environmentObject(deviceManager)
                
                // Tab Selection
                Picker("Analytics", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Usage").tag(1)
                    Text("Patterns").tag(2)
                    Text("Costs").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        DeviceOverviewTab(device: device)
                    case 1:
                        DeviceUsageTab(device: device)
                    case 2:
                        DevicePatternsTab(device: device)
                    case 3:
                        DeviceCostsTab(device: device)
                    default:
                        EmptyView()
                    }
                }
                .environmentObject(energyAnalytics)
                
                // Control Panel
                DeviceControlPanel(device: device, showScheduler: $showScheduler)
                    .environmentObject(deviceManager)
                
                // AI Recommendations
                DeviceAIRecommendations(device: device)
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showScheduler) {
            DeviceSchedulerView(device: device)
                .environmentObject(deviceManager)
        }
        .sheet(isPresented: $showSettings) {
            DeviceSettingsView(device: device)
                .environmentObject(deviceManager)
        }
    }
}

// MARK: - Device Header Card
struct DeviceHeaderCard: View {
    let device: SmartDevice
    @EnvironmentObject var deviceManager: DeviceManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Control
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(device.isOn ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        
                        Text(device.isOn ? "Active" : "Standby")
                            .font(.subheadline)
                            .foregroundColor(device.isOn ? .green : .gray)
                    }
                    
                    Text(device.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Label(device.room, systemImage: "location.fill")
                        Label(device.category.rawValue, systemImage: device.category.icon)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Power Button
                Button(action: { deviceManager.toggleDevice(device) }) {
                    ZStack {
                        Circle()
                            .fill(device.isOn ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "power")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Real-time Stats
            HStack(spacing: 15) {
                RealTimeStat(
                    label: "Current",
                    value: "\(String(format: "%.1f", device.currentUsage))W",
                    icon: "bolt.fill",
                    color: .yellow
                )
                
                RealTimeStat(
                    label: "Today",
                    value: "\(String(format: "%.2f", device.todayUsage))kWh",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                RealTimeStat(
                    label: "Cost",
                    value: "$\(String(format: "%.2f", device.estimatedDailyCost))",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                RealTimeStat(
                    label: "Efficiency",
                    value: "\(device.efficiencyRating)%",
                    icon: "leaf.fill",
                    color: .mint
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    device.category.color.opacity(0.3),
                    device.category.color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

// MARK: - Device Usage Tab
struct DeviceUsageTab: View {
    let device: SmartDevice
    @EnvironmentObject var energyAnalytics: EnergyAnalyticsViewModel
    @State private var selectedPeriod = UsagePeriod.day
    
    var body: some View {
        VStack(spacing: 20) {
            // Period Selector
            Picker("Period", selection: $selectedPeriod) {
                ForEach(UsagePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Usage Chart
            VStack(alignment: .leading, spacing: 10) {
                Text("Energy Consumption")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Chart(energyAnalytics.getDeviceUsageData(device: device, period: selectedPeriod)) { dataPoint in
                    if selectedPeriod == .day {
                        LineMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Usage", dataPoint.value)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Usage", dataPoint.value)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.green.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    } else {
                        BarMark(
                            x: .value("Time", dataPoint.timestamp),
                            y: .value("Usage", dataPoint.value)
                        )
                        .foregroundStyle(.green.gradient)
                        .cornerRadius(5)
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            
            // Usage Statistics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                UsageStatCard(title: "Peak Usage", value: "\(String(format: "%.2f", device.peakUsage))W", time: "2:30 PM")
                UsageStatCard(title: "Average", value: "\(String(format: "%.2f", device.averageUsage))W", time: "Daily")
                UsageStatCard(title: "Total Today", value: "\(String(format: "%.2f", device.todayUsage))kWh", time: "")
                UsageStatCard(title: "On Time", value: "\(device.onTimeToday)h", time: "Today")
            }
        }
    }
}

// MARK: - Supporting Types
enum DeviceCategory: String, CaseIterable, Codable {
    case all = "All"
    case lighting = "Lighting"
    case heating = "Heating"
    case cooling = "Cooling"
    case appliances = "Appliances"
    case electronics = "Electronics"
    case security = "Security"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .lighting: return "lightbulb.fill"
        case .heating: return "thermometer.sun.fill"
        case .cooling: return "snowflake"
        case .appliances: return "washer.fill"
        case .electronics: return "tv.fill"
        case .security: return "lock.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .lighting: return .yellow
        case .heating: return .orange
        case .cooling: return .blue
        case .appliances: return .purple
        case .electronics: return .indigo
        case .security: return .red
        }
    }
}

// Additional enums and helper views...
enum SortOption: String, CaseIterable {
    case name = "Name"
    case usage = "Usage"
    case room = "Room"
    case status = "Status"
    
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .usage: return "bolt.fill"
        case .room: return "house.fill"
        case .status: return "power"
        }
    }
}

enum UsagePeriod: String, CaseIterable {
    case day = "24H"
    case week = "7D"
    case month = "30D"
    case year = "1Y"
}

// Helper Views
struct CategoryChip: View {
    let category: DeviceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? category.color : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
        }
    }
}

struct QuickStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

struct RealTimeStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct UsageStatCard: View {
    let title: String
    let value: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            if !time.isEmpty {
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}
