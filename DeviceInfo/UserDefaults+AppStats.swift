//
//  UserDefaults+AppStats.swift
//  DeviceInfo
//
//  Created by Ben Cardy on 18/10/2022.
//

import Foundation

extension UserDefaults {
    
    enum AppStatsKey: String {
        case deviceID
        case storedCounters
        case storedGauges
        case storedEvents
    }
    
    var appStatsDeviceID: String? {
        get { string(forKey: AppStatsKey.deviceID.rawValue) }
        set { set(newValue, forKey: AppStatsKey.deviceID.rawValue) }
    }
    
    var appStatsStoredCounters: [String: AppStatsCounter] {
        get {
            let decoder = JSONDecoder()
            do {
                guard let storedData = data(forKey: AppStatsKey.storedCounters.rawValue) else {
                    return [:]
                }
                return try decoder.decode([String: AppStatsCounter].self, from: storedData)
            } catch {
                return [:]
            }
        }
        set {
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(newValue)
                setValue(encodedData, forKey: AppStatsKey.storedCounters.rawValue)
            } catch {
                
            }
        }
    }
    
    var appStatsStoredGauges: [AppStatsGauge] {
        get {
            let decoder = JSONDecoder()
            do {
                guard let storedData = data(forKey: AppStatsKey.storedGauges.rawValue) else {
                    return []
                }
                return try decoder.decode([AppStatsGauge].self, from: storedData)
            } catch {
                return []
            }
        }
        set {
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(newValue)
                setValue(encodedData, forKey: AppStatsKey.storedGauges.rawValue)
            } catch {
                
            }
        }
    }
    
    var appStatsStoredEvents: [AppStatsEvent] {
        get {
            let decoder = JSONDecoder()
            do {
                guard let storedData = data(forKey: AppStatsKey.storedEvents.rawValue) else {
                    return []
                }
                return try decoder.decode([AppStatsEvent].self, from: storedData)
            } catch {
                return []
            }
        }
        set {
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(newValue)
                setValue(encodedData, forKey: AppStatsKey.storedEvents.rawValue)
            } catch {
                
            }
        }
    }
    
}
