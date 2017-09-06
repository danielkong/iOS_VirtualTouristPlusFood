//
//  FirebaseEvents.swift
//  Virtual Tourist Plus Food
//
//  Created by Daniel Kong on 8/30/17.
//  Copyright © 2017 Daniel Kong. All rights reserved.
//

import Foundation

// if need objc support, add @objc
public enum MapType: Int {
    case Standard
    case Satellite
    case Hybrid
    
    public var toString: String {
        switch self {
        case .Standard:
            return "Standard"
        case .Satellite:
            return "Satellite"
        case .Hybrid:
            return "Hybrid"
        }
    }
}

public enum ViewType: String {
    case Scenery
    case Restaurant
    
    public var toString: String {
        switch self {
        case .Restaurant:
            return "Restaurant"
        case .Scenery:
            return "Scenery"
        }
    }
}

open class FirebaseEvents: NSObject {
    public struct ContentType {
        static let kIOSVersion = "iOS Version"
        static let kAppVersion = "App Version"
        static let kMapType = "Map Type"
        static let kViewType = "View Type"
        static let kDelete = "Delete"
        static let kRestaurant = "Restaurant"
        static let kToYelp = "To Yelp Page"
        static let kUnImplementation = "Un-implementation function"
    }
    
    public struct UnImplementation {
        static let kOpenImage = "Open Image"
    }
}
