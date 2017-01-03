//
//  ViewController.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 11/20/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import CoreData
import UIKit

class ViewController: UIViewController {    
    lazy var context: NSManagedObjectContext = {
        return CoreDataStack.sharedInstance().context
    } ()
}

