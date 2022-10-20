//
//  ContentView.swift
//  DeviceInfo
//
//  Created by Ben Cardy on 12/10/2022.
//

import SwiftUI

struct KeyValuePair: View {
    let key: String
    let value: String
    var body: some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.secondary)
        }
    }
}

struct ContentView: View {
    
    @EnvironmentObject private var appStats: AppStats
    
    var body: some View {
        List {
            Section {
                KeyValuePair(key: "iPhone", value: DeviceInfo.isPhone ? "true" : "false")
                KeyValuePair(key: "iPad", value: DeviceInfo.isPad ? "true" : "false")
                KeyValuePair(key: "Mac", value: DeviceInfo.isMac ? "true" : "false")
            }
            Section {
                if let screenSize = DeviceInfo.screenSize {
                    KeyValuePair(key: "Screen Size", value: "\(screenSize.width)×\(screenSize.height)")
                } else {
                    KeyValuePair(key: "Screen Size", value: "Unknown")
                }
                KeyValuePair(key: "OS Name", value: DeviceInfo.osName)
                KeyValuePair(key: "OS Version", value: DeviceInfo.osVersion)
                KeyValuePair(key: "Extended OS Version", value: DeviceInfo.extendedOSVersion)
                KeyValuePair(key: "Model", value: DeviceInfo.model)
                KeyValuePair(key: "Device ID", value: DeviceInfo.deviceID)
            }
            Section {
                Button(action: {
                    appStats.counter("foo", count: 1)
                }) {
                    Text("Count!")
                }
                Button(action: {
                    appStats.gauge("someOtherGauge", value: 1)
                }) {
                    Text("Gauge!")
                }
                Button(action: {
                    appStats.event("buttonPressed", attributes: ["foo": "bar"])
                }) {
                    Text("Event!")
                }
            }
            Section {
                Button(action: {
                    Task {
                        await appStats.postData()
                    }
                }) {
                    Text("Post data!")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
