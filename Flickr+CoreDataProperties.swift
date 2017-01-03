//
//  Flickr+CoreDataProperties.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/4/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData


extension Flickr {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Flickr");
    }

    @NSManaged public var nextPage: Int32
    @NSManaged public var totalPages: Int32
    @NSManaged public var pin: Pin?

}
