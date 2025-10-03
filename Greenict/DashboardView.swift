//
//  DashboardView.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Charts
import Combine

// MARK: - Main Dashboard View
struct DashboardView: View {
    @EnvironmentObject var deviceManager: DeviceManager
    @EnvironmentObject var energyAnalytics: EnergyAnalyticsViewModel
    @EnvironmentObject var aiOptimizer: AIEnergyOptimizer
    
    @State private var selectedTimeRange = TimeRange.today
    @State private var showAISuggestions = false
    @State private var currentUsage: Double = 0
    @State private var refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats Cards
                    HeaderStatsView(currentUsage: $currentUsage)
                        .environmentObject(energyAnalytics)
                    
                    // Real-time Usage Chart
                    RealTimeChartView(selectedRange: $selectedTimeRange)
                        .environmentObject(energyAnalytics)
                    
                    // AI Insights Card
                    AIInsightsCard(showSuggestions: $showAISuggestions)
                        .environmentObject(aiOptimizer)
                    
                    // Device Quick Controls
                    DeviceQuickControlsView()
                        .environmentObject(deviceManager)
                    
                    // Room-by-Room Breakdown
                    RoomBreakdownView()
                        .environmentObject(deviceManager)
                    
                    // Cost Analysis Card
                    CostAnalysisCard()
                        .environmentObject(energyAnalytics)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Energy Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAISuggestions.toggle() }) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showAISuggestions) {
                AISuggestionsView()
                    .environmentObject(aiOptimizer)
            }
            .onReceive(refreshTimer) { _ in
                updateRealTimeData()
            }
        }
    }
    
    private func updateRealTimeData() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentUsage = energyAnalytics.getCurrentUsage()
            energyAnalytics.updateRealTimeData()
        }
    }
}

// MARK: - Header Stats View
struct HeaderStatsView: View {
    @Binding var currentUsage: Double
    @EnvironmentObject var energyAnalytics: EnergyAnalyticsViewModel
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            StatCard(
                title: "Current Usage",
                value: String(format: "%.2f kW", currentUsage),
                icon: "bolt.fill",
                color: .green,
                trend: energyAnalytics.currentTrend
            )
            
            StatCard(
                title: "Today's Cost",
                value: String(format: "$%.2f", energyAnalytics.todaysCost),
                icon: "dollarsign.circle.fill",
                color: .blue,
                trend: energyAnalytics.costTrend
            )
            
            StatCard(
                title: "Monthly Usage",
                value: String(format: "%.0f kWh", energyAnalytics.monthlyUsage),
                icon: "calendar",
                color: .orange,
                trend: energyAnalytics.monthlyTrend
            )
            
            StatCard(
                title: "CO₂ Saved",
                value: String(format: "%.1f kg", energyAnalytics.co2Saved),
                icon: "leaf.fill",
                color: .mint,
                trend: .positive
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                TrendIndicator(direction: trend)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Real-time Chart View
struct RealTimeChartView: View {
    @Binding var selectedRange: TimeRange
    @EnvironmentObject var energyAnalytics: EnergyAnalyticsViewModel
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Live Energy Usage")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            Chart(energyAnalytics.chartData) { dataPoint in
                if selectedRange == .today {
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Usage", dataPoint.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.green, .green.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(Color.gray)
                }
            }
            .opacity(animateChart ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: animateChart)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .onAppear {
            animateChart = true
        }
    }
}

// MARK: - AI Insights Card
struct AIInsightsCard: View {
    @Binding var showSuggestions: Bool
    @EnvironmentObject var aiOptimizer: AIEnergyOptimizer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.green)
                Text("AI Energy Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showSuggestions = true
                }
                .font(.caption)
                .foregroundColor(.green)
            }
            
            if let topInsight = aiOptimizer.getTopInsight() {
                HStack(spacing: 10) {
                    Circle()
                        .fill(topInsight.priority.color)
                        .frame(width: 8, height: 8)
                    
                    Text(topInsight.message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text("Save \(topInsight.savingsPotential)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.vertical, 5)
            }
            
            // Quick Actions based on AI
            HStack(spacing: 10) {
                ForEach(aiOptimizer.quickActions.prefix(3), id: \.id) { action in
                    Button(action: { aiOptimizer.executeAction(action) }) {
                        Label(action.name, systemImage: action.icon)
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Device Quick Controls
struct DeviceQuickControlsView: View {
    @EnvironmentObject var deviceManager: DeviceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Quick Controls")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: DevicesListView()) {
                    Text("All Devices")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                ForEach(deviceManager.favoriteDevices.prefix(8)) { device in
                    DeviceQuickControl(device: device)
                        .environmentObject(deviceManager)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Device Quick Control
struct DeviceQuickControl: View {
    let device: SmartDevice
    @EnvironmentObject var deviceManager: DeviceManager
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { deviceManager.toggleDevice(device) }) {
                ZStack {
                    Circle()
                        .fill(device.isOn ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: device.icon)
                        .font(.title2)
                        .foregroundColor(device.isOn ? .green : .gray)
                }
            }
            
            Text(device.name)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Text("\(String(format: "%.1f", device.currentUsage))W")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(device.isOn ? .green : .gray)
        }
    }
}

// MARK: - Supporting Types
enum TimeRange: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

enum TrendDirection {
    case positive, negative, neutral
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .positive: return "arrow.up.right"
        case .negative: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
}

struct TrendIndicator: View {
    let direction: TrendDirection
    
    var body: some View {
        Image(systemName: direction.icon)
            .font(.caption)
            .foregroundColor(direction.color)
            .padding(4)
            .background(direction.color.opacity(0.2))
            .cornerRadius(4)
    }
}
