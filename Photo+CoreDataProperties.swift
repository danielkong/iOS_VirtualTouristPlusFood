//
//  Photo+CoreDataProperties.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/5/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public override class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Photo");
    }
    
    @NSManaged public var id: String?
    @NSManaged public var url: String?
    @NSManaged public var photoImage: NSData?
    @NSManaged public var pin: Pin?

}
