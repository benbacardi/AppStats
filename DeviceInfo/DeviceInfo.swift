//
//  DeviceInfo.swift
//  DeviceInfo
//
//  Created by Ben Cardy on 12/10/2022.
//

#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

import CoreGraphics


struct DeviceScreenSize {
    let width: CGFloat
    let height: CGFloat
}


struct DeviceInfo {
    
    // ID
    
    public static var deviceID: String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN"
        #else
        let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        defer{ IOObjectRelease(platformExpert) }

        guard platformExpert != 0 else { return "NOT FOUND" }
        return IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String ?? "UNKNOWN"
        #endif
    }
    
    // Device Type
    
    public static var isPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }
    
    public static var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
    
    public static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    public static var model: String {
        #if os(iOS)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return identifier }
          return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #else
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            if let modelIdentifierCString = String(data: modelData, encoding: .utf8)?.cString(using: .utf8) {
                modelIdentifier = String(cString: modelIdentifierCString)
            }
        }
        IOObjectRelease(service)
        return modelIdentifier ?? "UNKNOWN"
        #endif
    }
    
    // Screen Size
    
    public static var screenSize: DeviceScreenSize? {
        #if os(iOS)
        let bounds = UIScreen.main.bounds
        return DeviceScreenSize(width: bounds.width, height: bounds.height)
        #else
        if let screen = NSScreen.main {
            return DeviceScreenSize(width: screen.frame.width, height: screen.frame.height)
        } else {
            return nil
        }
        #endif
    }
    
    // OS
    
    public static var osName: String {
        #if os(iOS)
        return UIDevice.current.systemName
        #else
        return "macOS"
        #endif
    }
    
    public static var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #else
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let prefix = "\(version.majorVersion).\(version.minorVersion)"
        if version.patchVersion != 0 {
            return "\(prefix).\(version.patchVersion)"
        } else {
            return prefix
        }
        #endif
    }
    
    public static var extendedOSVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }
    
}
