//
//  AppStats.swift
//  DeviceInfo
//
//  Created by Ben Cardy on 12/10/2022.
//

import os.log
import Foundation

#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

enum AppStatsStandardCounter: String {
    case appLaunched
}

struct AppStatsCounter: Codable {
    let name: String
    let count: Int
    let dateCreated: Date
    let dateUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case count
        case dateCreated
        case dateUpdated
    }
    
    init(name: String, count: Int, dateCreated: Date, dateUpdated: Date) {
        self.name = name
        self.count = count
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.count = try container.decode(Int.self, forKey: .count)
        self.dateCreated = Date(timeIntervalSince1970: TimeInterval(try container.decode(Int.self, forKey: .dateCreated)))
        self.dateUpdated = Date(timeIntervalSince1970: TimeInterval(try container.decode(Int.self, forKey: .dateUpdated)))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(count, forKey: .count)
        try container.encode(Int(dateCreated.timeIntervalSince1970), forKey: .dateCreated)
        try container.encode(Int(dateUpdated.timeIntervalSince1970), forKey: .dateUpdated)
    }
    
}

struct AppStatsGauge: Codable {
    let name: String
    let value: Float
    let dateCreated: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case value
        case dateCreated
    }
    
    init(name: String, value: Float, dateCreated: Date) {
        self.name = name
        self.value = value
        self.dateCreated = dateCreated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.value = try container.decode(Float.self, forKey: .value)
        self.dateCreated = Date(timeIntervalSince1970: TimeInterval(try container.decode(Int.self, forKey: .dateCreated)))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(Int(dateCreated.timeIntervalSince1970), forKey: .dateCreated)
    }
    
}

struct AppStatsEvent: Codable {
    let name: String
    let attributes: [String: String]?
    let dateCreated: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case attributes
        case dateCreated
    }
    
    init(name: String, attributes: [String: String]? = nil, dateCreated: Date) {
        self.name = name
        self.attributes = attributes
        self.dateCreated = dateCreated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.attributes = try container.decode([String: String].self, forKey: .attributes)
        self.dateCreated = Date(timeIntervalSince1970: TimeInterval(try container.decode(Int.self, forKey: .dateCreated)))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(Int(dateCreated.timeIntervalSince1970), forKey: .dateCreated)
    }
    
}

extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}

extension String {
    func dateFromISOString() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}

struct AppStatsDeviceInfo: Codable {
    let device_id: String
    let model: String
    let app_version: String
    let build_number: String
    let os_name: String
    let os_version: String
    let os_version_string: String
}

struct AppStatsCountersPOSTRequestBody: Codable {
    let counters: [AppStatsCounter]
    let device: AppStatsDeviceInfo
}

struct AppStatsGaugesPOSTRequestBody: Codable {
    let gauges: [AppStatsGauge]
    let device: AppStatsDeviceInfo
}

struct AppStatsEventsPOSTRequestBody: Codable {
    let events: [AppStatsEvent]
    let device: AppStatsDeviceInfo
}

class AppStats: ObservableObject {
    
    private static let logger = Logger(OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "AppStats"))

    let endpoint: URL
    let appName: String
    let key: String
    
    let deviceID: String
    
    let maxValuesBeforePost: Int
    
    var storedCounters: [String: AppStatsCounter] = [:]
    var storedGauges: [AppStatsGauge] = []
    var storedEvents: [AppStatsEvent] = []
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier? = nil
    
    public init(endpoint: URL, appName: String, key: String) {
        
        AppStats.logger.info("Initialising AppStats for \(appName) to \(endpoint)")
        
        self.endpoint = endpoint
        self.appName = appName
        self.key = key
        self.maxValuesBeforePost = 2
        
        if let storedDeviceId = UserDefaults.standard.appStatsDeviceID {
            self.deviceID = storedDeviceId
        } else {
            self.deviceID = UUID().uuidString
            UserDefaults.standard.appStatsDeviceID = self.deviceID
        }
        
        self.storedCounters = UserDefaults.standard.appStatsStoredCounters
        self.storedGauges = UserDefaults.standard.appStatsStoredGauges
        self.storedEvents = UserDefaults.standard.appStatsStoredEvents
        
        self.counter(AppStatsStandardCounter.appLaunched)
        
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedDismissNotification(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedDismissNotification(_:)), name: UIApplication.willTerminateNotification, object: nil)
        #endif
        #if os(macOS)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedDismissNotification(_:)), name: NSApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedDismissNotification(_:)), name: NSApplication.willTerminateNotification, object: nil)
        #endif
        
    }
    
    @objc private func receivedDismissNotification(_ notification: Notification) {
        
        AppStats.logger.debug("Dismiss event recevied")
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(
            withName: "Post AppStats Data",
            expirationHandler: {
                AppStats.logger.debug("Background task expired \(self.backgroundTaskID?.rawValue ?? 1)")
                if let backgroundTaskID = self.backgroundTaskID {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }
        )
        
        AppStats.logger.debug("Background task \(self.backgroundTaskID?.rawValue ?? 1)")
        
        Task {
            await self.postData()
            AppStats.logger.debug("Persist data")
            UserDefaults.standard.appStatsStoredCounters = self.storedCounters
            UserDefaults.standard.appStatsStoredEvents = self.storedEvents
            UserDefaults.standard.appStatsStoredGauges = self.storedGauges
            AppStats.logger.debug("Ending background task \(self.backgroundTaskID?.rawValue ?? 1)")
            if let backgroundTaskID = self.backgroundTaskID {
                await UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
        }
        
    }
    
    func getDeviceInfo() -> AppStatsDeviceInfo {
        AppStatsDeviceInfo(device_id: self.deviceID, model: DeviceInfo.model, app_version: "1.0", build_number: "123", os_name: DeviceInfo.osName, os_version: DeviceInfo.osVersion, os_version_string: DeviceInfo.extendedOSVersion)
    }
    
    public func postData() async {
        AppStats.logger.info("Posting data to \(self.endpoint)")
        await postCounters()
        await postGauges()
        await postEvents()
        AppStats.logger.info("Data post complete")
    }
    
    func postCounters() async {
        if !storedCounters.isEmpty {
            AppStats.logger.info("Posting \(self.storedCounters.count) counters")
            var counterURL = endpoint.appendingPathComponent("api/counters/\(appName)/")
            counterURL.append(queryItems: [URLQueryItem(name: "key", value: key)])
            var urlRequest = URLRequest(url: counterURL)
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpMethod = "POST"
            let body = AppStatsCountersPOSTRequestBody(counters: Array(storedCounters.values), device: getDeviceInfo())
            do {
                let data = try JSONEncoder().encode(body)
                let (responseData, response) = try await URLSession.shared.upload(for: urlRequest, from: data)
                let responseString = String(data: responseData, encoding: .utf8) ?? "INVALID_DATA"
                if let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 {
                    AppStats.logger.info("Counters updated: \(responseString)")
                    storedCounters = [:]
                } else {
                    AppStats.logger.error("Counters not updated: \(responseString)")
                }
            } catch {
                AppStats.logger.error("Could not post counters: \(error.localizedDescription)")
            }
        }
    }
    
    func postGauges() async {
        if !storedGauges.isEmpty {
            AppStats.logger.info("Posting \(self.storedGauges.count) gauges")
            var counterURL = endpoint.appendingPathComponent("api/gauges/\(appName)/")
            counterURL.append(queryItems: [URLQueryItem(name: "key", value: key)])
            var urlRequest = URLRequest(url: counterURL)
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpMethod = "POST"
            let body = AppStatsGaugesPOSTRequestBody(gauges: storedGauges, device: getDeviceInfo())
            do {
                let data = try JSONEncoder().encode(body)
                let (responseData, response) = try await URLSession.shared.upload(for: urlRequest, from: data)
                let responseString = String(data: responseData, encoding: .utf8) ?? "INVALID_DATA"
                if let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 {
                    AppStats.logger.info("Gauges updated: \(responseString)")
                    storedGauges = []
                } else {
                    AppStats.logger.error("Gauges not updated: \(responseString)")
                }
            } catch {
                AppStats.logger.error("Could not post gauges: \(error.localizedDescription)")
            }
        }
    }
    
    func postEvents() async {
        if !storedEvents.isEmpty {
            AppStats.logger.info("Posting \(self.storedEvents.count) events")
            var counterURL = endpoint.appendingPathComponent("api/events/\(appName)/")
            counterURL.append(queryItems: [URLQueryItem(name: "key", value: key)])
            var urlRequest = URLRequest(url: counterURL)
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpMethod = "POST"
            let body = AppStatsEventsPOSTRequestBody(events: storedEvents, device: getDeviceInfo())
            do {
                let data = try JSONEncoder().encode(body)
                let (responseData, response) = try await URLSession.shared.upload(for: urlRequest, from: data)
                let responseString = String(data: responseData, encoding: .utf8) ?? "INVALID_DATA"
                if let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 {
                    AppStats.logger.info("Events updated: \(responseString)")
                    storedEvents = []
                } else {
                    AppStats.logger.error("Events not updated: \(responseString)")
                }
            } catch {
                AppStats.logger.error("Could not post events: \(error.localizedDescription)")
            }
        }
    }
    
    public func postIfMaxValuesReached() {
        if storedCounters.count + storedEvents.count + storedGauges.count > maxValuesBeforePost {
            Task {
                await postData()
            }
        }
    }
    
    public func counter(_ name: String, count: Int = 1) {
        AppStats.logger.info("Incrementing counter \(name) by \(count)")
        let now = Date()
        let counter: AppStatsCounter
        if let existingCounter = storedCounters[name] {
            counter = AppStatsCounter(name: name, count: existingCounter.count + count, dateCreated: existingCounter.dateCreated, dateUpdated: now)
        } else {
            counter = AppStatsCounter(name: name, count: count, dateCreated: now, dateUpdated: now)
        }
        AppStats.logger.info("Internal counter \(name) updated: \(counter.count)")
        storedCounters[name] = counter
        postIfMaxValuesReached()
    }
    
    public func counter<T: RawRepresentable>(_ name: T, count: Int = 1) where T.RawValue == String {
        counter(name.rawValue, count: count)
    }
    
    public func gauge(_ name: String, value: Float = 1) {
        AppStats.logger.info("Registering gauge \(name) with value \(value)")
        let gauge = AppStatsGauge(name: name, value: value, dateCreated: Date())
        storedGauges.append(gauge)
        postIfMaxValuesReached()
    }
    
    public func gauge<T: RawRepresentable>(_ name: T, value: Float = 1) where T.RawValue == String {
        gauge(name.rawValue, value: value)
    }
    
    public func event(_ name: String, attributes: [String: String]? = nil) {
        if let attributes = attributes {
            AppStats.logger.info("Registering event \(name) with attributes \(attributes)")
        } else {
            AppStats.logger.info("Registering event \(name)")
        }
        let event = AppStatsEvent(name: name, attributes: attributes, dateCreated: Date())
        storedEvents.append(event)
        postIfMaxValuesReached()
    }
    
    public func event<T: RawRepresentable>(_ name: T, attributes: [String: String]? = nil) where T.RawValue == String {
        event(name.rawValue, attributes: attributes)
    }
    
}
