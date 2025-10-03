//
//  ViewModels.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import Combine

// MARK: - Authentication View Model
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func checkAuthStatus() {
        currentUser = Auth.auth().currentUser
        isAuthenticated = currentUser != nil
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                self?.isAuthenticated = true
                completion(true, nil)
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else if let user = result?.user {
                // Create user profile in Firestore
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "fullName": fullName,
                    "email": email,
                    "createdAt": Timestamp(),
                    "energyGoal": 100.0,
                    "notifications": true
                ]) { error in
                    if let error = error {
                        completion(false, error.localizedDescription)
                    } else {
                        self?.isAuthenticated = true
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    func signInAsGuest() {
        Auth.auth().signInAnonymously { [weak self] _, error in
            if error == nil {
                self?.isAuthenticated = true
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// MARK: - Device Manager
class DeviceManager: ObservableObject {
    @Published var devices: [SmartDevice] = []
    @Published var rooms: [String] = ["Living Room", "Kitchen", "Bedroom", "Bathroom", "Office", "Garage"]
    @Published var favoriteDevices: [SmartDevice] = []
    
    private var database = Database.database().reference()
    private var devicesListener: DatabaseHandle?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDevices()
        setupRealtimeUpdates()
        generateMockDevices() // For demo purposes
    }
    
    func setupRealtimeUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        devicesListener = database.child("users/\(userId)/devices").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            var newDevices: [SmartDevice] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let device = SmartDevice(from: dict, id: childSnapshot.key) {
                    newDevices.append(device)
                }
            }
            
            DispatchQueue.main.async {
                self.devices = newDevices
                self.updateFavorites()
            }
        }
    }
    
    func toggleDevice(_ device: SmartDevice) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        
        devices[index].isOn.toggle()
        
        // Update Firebase
        if let userId = Auth.auth().currentUser?.uid {
            database.child("users/\(userId)/devices/\(device.id)/isOn")
                .setValue(devices[index].isOn)
        }
        
        // Simulate power usage change
        if devices[index].isOn {
            devices[index].currentUsage = devices[index].averageUsage
        } else {
            devices[index].currentUsage = 0
        }
        
        objectWillChange.send()
    }
    
    func addDevice(_ device: SmartDevice) {
        devices.append(device)
        
        // Save to Firebase
        if let userId = Auth.auth().currentUser?.uid {
            let deviceData = device.toDictionary()
            database.child("users/\(userId)/devices/\(device.id)")
                .setValue(deviceData)
        }
    }
    
    func deleteDevice(_ device: SmartDevice) {
        devices.removeAll { $0.id == device.id }
        
        // Remove from Firebase
        if let userId = Auth.auth().currentUser?.uid {
            database.child("users/\(userId)/devices/\(device.id)")
                .removeValue()
        }
    }
    
    func updateDevice(_ device: SmartDevice) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index] = device
        
        // Update Firebase
        if let userId = Auth.auth().currentUser?.uid {
            let deviceData = device.toDictionary()
            database.child("users/\(userId)/devices/\(device.id)")
                .setValue(deviceData)
        }
    }
    
    func setSchedule(for device: SmartDevice, schedule: DeviceSchedule) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index].schedule = schedule
        updateDevice(devices[index])
    }
    
    private func updateFavorites() {
        favoriteDevices = devices.filter { $0.isFavorite }.prefix(8).map { $0 }
    }
    
    private func loadDevices() {
        // Load from Firebase or local storage
    }
    
    // Generate mock devices for demo
    private func generateMockDevices() {
        let mockDevices = [
            SmartDevice(name: "Living Room Light", room: "Living Room", category: .lighting, icon: "lightbulb.fill"),
            SmartDevice(name: "Smart TV", room: "Living Room", category: .electronics, icon: "tv.fill"),
            SmartDevice(name: "Air Conditioner", room: "Living Room", category: .cooling, icon: "air.conditioner.horizontal.fill"),
            SmartDevice(name: "Kitchen Light", room: "Kitchen", category: .lighting, icon: "lightbulb.fill"),
            SmartDevice(name: "Refrigerator", room: "Kitchen", category: .appliances, icon: "refrigerator.fill"),
            SmartDevice(name: "Dishwasher", room: "Kitchen", category: .appliances, icon: "dishwasher.fill"),
            SmartDevice(name: "Bedroom Light", room: "Bedroom", category: .lighting, icon: "lightbulb.fill"),
            SmartDevice(name: "Smart Heater", room: "Bedroom", category: .heating, icon: "heater.vertical.fill"),
            SmartDevice(name: "Desktop Computer", room: "Office", category: .electronics, icon: "desktopcomputer"),
            SmartDevice(name: "Security Camera", room: "Garage", category: .security, icon: "video.fill"),
        ]
        
        devices = mockDevices
        favoriteDevices = Array(mockDevices.prefix(4))
    }
}

// MARK: - Energy Analytics View Model
class EnergyAnalyticsViewModel: ObservableObject {
    @Published var chartData: [ChartDataPoint] = []
    @Published var currentUsage: Double = 0.0
    @Published var todaysCost: Double = 0.0
    @Published var monthlyUsage: Double = 0.0
    @Published var co2Saved: Double = 0.0
    @Published var currentTrend: TrendDirection = .neutral
    @Published var costTrend: TrendDirection = .neutral
    @Published var monthlyTrend: TrendDirection = .neutral
    
    private var database = Database.database().reference()
    private var timer: Timer?
    private let kwhRate = 0.12 // $0.12 per kWh
    
    init() {
        setupRealtimeData()
        generateMockData()
    }
    
    func setupRealtimeData() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateRealTimeData()
        }
    }
    
    func updateRealTimeData() {
        // Simulate real-time data updates
        let variation = Double.random(in: -0.5...0.5)
        currentUsage = max(0, currentUsage + variation)
        
        // Update chart with new data point
        let newPoint = ChartDataPoint(
            timestamp: Date(),
            value: currentUsage,
            label: DateFormatter.shortTime.string(from: Date())
        )
        
        chartData.append(newPoint)
        
        // Keep only last 50 points for performance
        if chartData.count > 50 {
            chartData.removeFirst()
        }
        
        // Update costs
        todaysCost = calculateTodaysCost()
        monthlyUsage = calculateMonthlyUsage()
        co2Saved = calculateCO2Saved()
        
        // Update trends
        updateTrends()
    }
    
    func getCurrentUsage() -> Double {
        // Sum of all active devices
        return DeviceManager().devices
            .filter { $0.isOn }
            .reduce(0) { $0 + $1.currentUsage / 1000 } // Convert W to kW
    }
    
    func getDeviceUsageData(device: SmartDevice, period: UsagePeriod) -> [ChartDataPoint] {
        // Generate mock data based on period
        var data: [ChartDataPoint] = []
        let now = Date()
        
        switch period {
        case .day:
            for hour in 0..<24 {
                let date = Calendar.current.date(byAdding: .hour, value: -hour, to: now)!
                let value = Double.random(in: 50...200) * (device.isOn ? 1.0 : 0.3)
                data.append(ChartDataPoint(
                    timestamp: date,
                    value: value,
                    label: DateFormatter.shortTime.string(from: date)
                ))
            }
        case .week:
            for day in 0..<7 {
                let date = Calendar.current.date(byAdding: .day, value: -day, to: now)!
                let value = Double.random(in: 2...8) * (device.isOn ? 1.0 : 0.3)
                data.append(ChartDataPoint(
                    timestamp: date,
                    value: value,
                    label: DateFormatter.shortDate.string(from: date)
                ))
            }
        case .month:
            for day in 0..<30 {
                let date = Calendar.current.date(byAdding: .day, value: -day, to: now)!
                let value = Double.random(in: 2...8) * (device.isOn ? 1.0 : 0.3)
                data.append(ChartDataPoint(
                    timestamp: date,
                    value: value,
                    label: DateFormatter.shortDate.string(from: date)
                ))
            }
        case .year:
            for month in 0..<12 {
                let date = Calendar.current.date(byAdding: .month, value: -month, to: now)!
                let value = Double.random(in: 60...240) * (device.isOn ? 1.0 : 0.3)
                data.append(ChartDataPoint(
                    timestamp: date,
                    value: value,
                    label: DateFormatter.monthYear.string(from: date)
                ))
            }
        }
        
        return data.reversed()
    }
    
    private func calculateTodaysCost() -> Double {
        let todayUsage = chartData
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.value }
        return todayUsage * kwhRate
    }
    
    private func calculateMonthlyUsage() -> Double {
        // Mock calculation
        return Double.random(in: 450...650)
    }
    
    private func calculateCO2Saved() -> Double {
        // Mock calculation based on efficient usage
        return Double.random(in: 15...35)
    }
    
    private func updateTrends() {
        currentTrend = Bool.random() ? .positive : .negative
        costTrend = Bool.random() ? .neutral : .negative
        monthlyTrend = Bool.random() ? .positive : .neutral
    }
    
    private func generateMockData() {
        let now = Date()
        for i in 0..<20 {
            let timestamp = Calendar.current.date(byAdding: .minute, value: -i * 5, to: now)!
            let value = Double.random(in: 1.5...4.5)
            chartData.append(ChartDataPoint(
                timestamp: timestamp,
                value: value,
                label: DateFormatter.shortTime.string(from: timestamp)
            ))
        }
        chartData.reverse()
        
        currentUsage = 2.8
        todaysCost = 3.45
        monthlyUsage = 524.3
        co2Saved = 23.7
    }
}

// MARK: - AI Energy Optimizer
class AIEnergyOptimizer: ObservableObject {
    @Published var insights: [AIInsight] = []
    @Published var quickActions: [AIAction] = []
    @Published var savingsPotential: Double = 0.0
    @Published var optimizationScore: Int = 75
    
    init() {
        generateInsights()
        generateQuickActions()
    }
    
    func getTopInsight() -> AIInsight? {
        insights.first
    }
    
    func generateInsights() {
        insights = [
            AIInsight(
                id: UUID().uuidString,
                message: "Your AC is consuming 35% more energy than similar homes. Consider raising temperature by 2°F",
                priority: .high,
                savingsPotential: "$12/mo",
                category: "Cooling"
            ),
            AIInsight(
                id: UUID().uuidString,
                message: "Living room lights were left on for 3 hours while unoccupied yesterday",
                priority: .medium,
                savingsPotential: "$5/mo",
                category: "Lighting"
            ),
            AIInsight(
                id: UUID().uuidString,
                message: "Schedule your dishwasher to run during off-peak hours (11 PM - 6 AM)",
                priority: .low,
                savingsPotential: "$3/mo",
                category: "Appliances"
            )
        ]
    }
    
    func generateQuickActions() {
        quickActions = [
            AIAction(id: UUID().uuidString, name: "Eco Mode", icon: "leaf.fill", action: .ecoMode),
            AIAction(id: UUID().uuidString, name: "Sleep", icon: "moon.fill", action: .sleep),
            AIAction(id: UUID().uuidString, name: "Away", icon: "house.slash.fill", action: .away),
            AIAction(id: UUID().uuidString, name: "Optimize", icon: "wand.and.stars", action: .optimize)
        ]
    }
    
    func executeAction(_ action: AIAction) {
        switch action.action {
        case .ecoMode:
            applyEcoMode()
        case .sleep:
            applySleepMode()
        case .away:
            applyAwayMode()
        case .optimize:
            optimizeAllDevices()
        }
    }
    
    private func applyEcoMode() {
        // Reduce power consumption across all devices
    }
    
    private func applySleepMode() {
        // Turn off unnecessary devices for nighttime
    }
    
    private func applyAwayMode() {
        // Set devices to minimum power when away
    }
    
    private func optimizeAllDevices() {
        // AI-powered optimization of all devices
    }
}
