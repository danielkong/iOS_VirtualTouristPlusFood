//
//  MapViewController.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 11/22/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreData
import Firebase

class MapViewController: ViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var segment: UISegmentedControl!
    
    var yelpClient = YelpClientAPI()
    fileprivate let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    let kYelpAppID = "JGAl29kTR_1GNRPnj8XZzA"
    let kSecretKey = "SFHjUh3LX2ORlOoHIgIHhCeS1UIHnYZvjxBvMx5R3kptLt1LzXM44qptycMfksIP"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let yelp = YelpClientAPI()
        if Reachability.isConnectedToNetwork() != .notReachable {
            yelp.authWithAppID(kYelpAppID, secret: kSecretKey, completionHandler: {(client: YelpClientAPI?, error: String?) -> Void in
                guard error == nil else {
                    if error == "HTTP Errors" {
                        super.showConnectionAlertView(error)
                    }
                    return
                }
                self.yelpClient = client!
                self.appDelegate.yelpClient = client!
                if (client == nil) {
                    print("Authentication failed: \(error)")
                }
            })
        } else {
            super.showConnectionAlertView()
        }
        
        navigationItem.rightBarButtonItem = editButtonItem
        hintLabel.isHidden = true
        
        segment.addTarget(self, action: #selector(segementChanged), for: .valueChanged)
        mapView.delegate = self
        mapView.addAnnotations(showAllPins())
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.createPin(_:))))
    }
    
    func segementChanged() {
        let selectedIndex = segment.selectedSegmentIndex
        var mapType = MapType.Standard
        switch selectedIndex {
        case 0:
            segment.tintColor = UIColor(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
            mapView.mapType = .standard
        case 1:
            segment.tintColor = UIColor.white
            mapView.mapType = .satellite
        case 2:
            segment.tintColor = UIColor.white
            mapView.mapType = .hybrid
        default: break
        }
        mapType = MapType(rawValue: selectedIndex)!

        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "\(FirebaseEvents.ContentType.kMapType)-\(selectedIndex)" as NSObject,
            AnalyticsParameterItemName: mapType.toString as NSObject,
            AnalyticsParameterContentType: FirebaseEvents.ContentType.kMapType as NSObject
        ])
        
    }
    
    func showAllPins() -> [Pin] {
        return try! (context.fetch(NSFetchRequest(entityName: "Pin")) )
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
            ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pinView.animatesDrop = true
        pinView.isSelected = true
        pinView.isDraggable = true

        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if oldState == .ending && !isEditing {
            if let pin = view.annotation as? Pin {
                pin.deleteExistingPhotos(context, handler: { _ in
                    self.context.saveToManagedObjectContext()
                })
                pin.flickr?.loadNewPhotosAndAddToPin(context, handler: { _ in
                    self.context.saveToManagedObjectContext()
                })
            }
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation as? Pin {
            isEditing ? deletePin(pin) : viewPin(pin)
            mapView.deselectAnnotation(pin, animated: false)
        }
    }
    
    func deletePin(_ pin: Pin) {
        context.delete(pin)
        context.saveToManagedObjectContext()

        mapView.removeAnnotation(pin)
    }
    
    func viewPin(_ pin: Pin) {
        let controller = storyboard!.instantiateViewController(withIdentifier: "CollectionController") as! MapCollectionViewController
        controller.pin = pin
        controller.mapType = mapView.mapType
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func createPin(_ sender: UIGestureRecognizer) {
        if sender.state == .began {
            let locationCoordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let pin = Pin(latitude: Double(locationCoordinate.latitude), longitude: Double(locationCoordinate.longitude), context: context)
            if Reachability.isConnectedToNetwork() != .notReachable {
                pin.flickr?.loadNewPhotosAndAddToPin(context, handler: { _ in
                    self.context.saveToManagedObjectContext()
                })
                context.saveToManagedObjectContext()
            } else {
                super.showConnectionAlertView()
            }
            mapView.addAnnotation(pin)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        hintLabel.isHidden = !editing
    }
}
