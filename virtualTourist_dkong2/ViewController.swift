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
    
    func showConnectionAlertView(_ error: String? = "HTTP Errors") {
        DispatchQueue.main.async(execute: {
            var alertTitle = ""
            var alertMessage = ""
            switch error! {
            case "Connection timed out":
                alertTitle = error!
                alertMessage = error!
            case "HTTP Errors":
                alertTitle = "No Internet Connection"
                alertMessage = "Connect to the Internet to use this app. We use local data currently."
            case "SOCK Errors":
                alertTitle = "SOCK Error"
                alertMessage = "Connection got refused by SOCK errors."
            default: break
            }
            let alert = UIAlertController(title: alertTitle, message: alertMessage,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
}

