//
//  DataModels.swift
//  Greenict
//
//  Created by Unknown Friend on 03/10/2025.
//

import SwiftUI
import Foundation
import Firebase

// MARK: - Smart Device Model
struct SmartDevice: Identifiable, Codable {
    let id: String
    var name: String
    var room: String
    var category: DeviceCategory
    var icon: String
    var isOn: Bool
    var currentUsage: Double // in Watts
    var todayUsage: Double // in kWh
    var weekUsage: Double // in kWh
    var monthUsage: Double // in kWh
    var averageUsage: Double // in Watts
    var peakUsage: Double // in Watts
    var estimatedDailyCost: Double
    var efficiencyRating: Int // 0-100
    var isFavorite: Bool
    var schedule: DeviceSchedule?
    var onTimeToday: Int // hours
    var lastUpdated: Date
    var manufacturer: String?
    var model: String?
    var connectionType: ConnectionType
    var voiceAssistants: [VoiceAssistant]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        room: String,
        category: DeviceCategory,
        icon: String,
        isOn: Bool = false,
        currentUsage: Double = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.room = room
        self.category = category
        self.icon = icon
        self.isOn = isOn
        self.currentUsage = currentUsage
        self.isFavorite = isFavorite
        
        // Initialize with mock data
        self.todayUsage = Double.random(in: 1...5)
        self.weekUsage = Double.random(in: 10...35)
        self.monthUsage = Double.random(in: 40...150)
        self.averageUsage = Double.random(in: 50...200)
        self.peakUsage = Double.random(in: 100...400)
        self.estimatedDailyCost = todayUsage * 0.12
        self.efficiencyRating = Int.random(in: 65...95)
        self.onTimeToday = Int.random(in: 1...12)
        self.lastUpdated = Date()
        self.connectionType = .wifi
        self.voiceAssistants = [.googleHome, .alexa]
    }
    
    init?(from dict: [String: Any], id: String) {
        guard let name = dict["name"] as? String,
              let room = dict["room"] as? String,
              let categoryRaw = dict["category"] as? String,
              let icon = dict["icon"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.room = room
        self.category = DeviceCategory(rawValue: categoryRaw) ?? .electronics
        self.icon = icon
        self.isOn = dict["isOn"] as? Bool ?? false
        self.currentUsage = dict["currentUsage"] as? Double ?? 0
        self.todayUsage = dict["todayUsage"] as? Double ?? 0
        self.weekUsage = dict["weekUsage"] as? Double ?? 0
        self.monthUsage = dict["monthUsage"] as? Double ?? 0
        self.averageUsage = dict["averageUsage"] as? Double ?? 0
        self.peakUsage = dict["peakUsage"] as? Double ?? 0
        self.estimatedDailyCost = dict["estimatedDailyCost"] as? Double ?? 0
        self.efficiencyRating = dict["efficiencyRating"] as? Int ?? 75
        self.isFavorite = dict["isFavorite"] as? Bool ?? false
        self.onTimeToday = dict["onTimeToday"] as? Int ?? 0
        self.lastUpdated = Date()
        self.manufacturer = dict["manufacturer"] as? String
        self.model = dict["model"] as? String
        self.connectionType = ConnectionType(rawValue: dict["connectionType"] as? String ?? "") ?? .wifi
        self.voiceAssistants = []
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "room": room,
            "category": category.rawValue,
            "icon": icon,
            "isOn": isOn,
            "currentUsage": currentUsage,
            "todayUsage": todayUsage,
            "weekUsage": weekUsage,
            "monthUsage": monthUsage,
            "averageUsage": averageUsage,
            "peakUsage": peakUsage,
            "estimatedDailyCost": estimatedDailyCost,
            "efficiencyRating": efficiencyRating,
            "isFavorite": isFavorite,
            "onTimeToday": onTimeToday,
            "manufacturer": manufacturer ?? "",
            "model": model ?? "",
            "connectionType": connectionType.rawValue
        ]
    }
}

// MARK: - Device Schedule
struct DeviceSchedule: Codable {
    var isEnabled: Bool
    var scheduleItems: [ScheduleItem]
    
    struct ScheduleItem: Codable, Identifiable {
        let id = UUID().uuidString
        var days: [DayOfWeek]
        var startTime: Date
        var endTime: Date
        var action: ScheduleAction
    }
}

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let label: String
}

// MARK: - AI Insight
struct AIInsight {
    let id: String
    let message: String
    let priority: InsightPriority
    let savingsPotential: String
    let category: String
}

// MARK: - AI Action
struct AIAction {
    let id: String
    let name: String
    let icon: String
    let action: ActionType
}

// MARK: - Room Breakdown
struct RoomBreakdown: Identifiable {
    let id = UUID()
    let room: String
    let usage: Double
    let cost: Double
    let deviceCount: Int
    let activeDevices: Int
    let percentage: Double
}

// MARK: - Enums

enum ConnectionType: String, Codable, CaseIterable {
    case wifi = "WiFi"
    case zigbee = "Zigbee"
    case zwave = "Z-Wave"
    case bluetooth = "Bluetooth"
    case thread = "Thread"
}

enum VoiceAssistant: String, Codable, CaseIterable {
    case googleHome = "Google Home"
    case alexa = "Alexa"
    case siri = "Siri"
    case none = "None"
}

enum DayOfWeek: String, Codable, CaseIterable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"
}

enum ScheduleAction: String, Codable {
    case turnOn = "Turn On"
    case turnOff = "Turn Off"
    case setLevel = "Set Level"
    case ecoMode = "Eco Mode"
}

enum InsightPriority: String {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

enum ActionType {
    case ecoMode
    case sleep
    case away
    case optimize
}

// MARK: - Extensions

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
    
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm"
        return formatter
    }()
}

// MARK: - Mock Data Generator
struct MockDataGenerator {
    static func generateChartData(points: Int = 24) -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        let now = Date()
        
        for i in 0..<points {
            let timestamp = Calendar.current.date(byAdding: .hour, value: -i, to: now)!
            let value = Double.random(in: 1.5...4.5) + sin(Double(i) * 0.5) * 0.5
            data.append(ChartDataPoint(
                timestamp: timestamp,
                value: max(0, value),
                label: DateFormatter.shortTime.string(from: timestamp)
            ))
        }
        
        return data.reversed()
    }
    
    static func generateRoomBreakdown() -> [RoomBreakdown] {
        return [
            RoomBreakdown(room: "Living Room", usage: 45.2, cost: 5.42, deviceCount: 5, activeDevices: 3, percentage: 35),
            RoomBreakdown(room: "Kitchen", usage: 38.7, cost: 4.64, deviceCount: 4, activeDevices: 2, percentage: 30),
            RoomBreakdown(room: "Bedroom", usage: 19.3, cost: 2.32, deviceCount: 3, activeDevices: 1, percentage: 15),
            RoomBreakdown(room: "Office", usage: 12.9, cost: 1.55, deviceCount: 3, activeDevices: 2, percentage: 10),
            RoomBreakdown(room: "Bathroom", usage: 6.5, cost: 0.78, deviceCount: 2, activeDevices: 1, percentage: 5),
            RoomBreakdown(room: "Garage", usage: 6.5, cost: 0.78, deviceCount: 2, activeDevices: 0, percentage: 5)
        ]
    }
}
