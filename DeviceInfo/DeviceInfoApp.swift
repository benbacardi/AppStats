//
//  DeviceInfoApp.swift
//  DeviceInfo
//
//  Created by Ben Cardy on 12/10/2022.
//

import SwiftUI

@main
struct DeviceInfoApp: App {
    
    @StateObject private var appStats = AppStats(endpoint: URL(string: "http://192.168.1.94:8000")!, appName: "DeviceInfo", key: "foobar")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appStats)
        }
    }
}
