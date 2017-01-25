//
//  Business+CoreDataProperties.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/13/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData


extension Business {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Business");
    }

    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var categories: String?
    @NSManaged public var distance: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var id: String?
    @NSManaged public var phone: String?
    @NSManaged public var isClosed: Bool
    @NSManaged public var url: String?
    @NSManaged public var rating: Double
    
    @NSManaged public var pin: Pin?

}
