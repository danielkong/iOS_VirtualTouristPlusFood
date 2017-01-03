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

class MapViewController: ViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
    var yelpClient = YelpClientAPI()
    private let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let yelp = YelpClientAPI()
        yelp.authWithAppID("JGAl29kTR_1GNRPnj8XZzA", secret: "SFHjUh3LX2ORlOoHIgIHhCeS1UIHnYZvjxBvMx5R3kptLt1LzXM44qptycMfksIP", completionHandler: {(client: YelpClientAPI?, error: String?) -> Void in
            self.yelpClient = client!
            self.appDelegate.yelpClient = client!
            if (client == nil) {
                print("Authentication failed: \(error)")
            } else {
                print(self.appDelegate.sharedYelpClient?.accessToken)
            }
        })
        
        navigationItem.rightBarButtonItem = editButtonItem()
        hintLabel.hidden = true
        
        mapView.delegate = self
        mapView.addAnnotations(showAllPins())
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.createPin(_:))))
    }
    
    func showAllPins() -> [Pin] {
        return try! (context.executeFetchRequest(NSFetchRequest(entityName: "Pin")) as! [Pin]) ?? []
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView
            ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pinView.animatesDrop = true
        pinView.selected = true
        pinView.draggable = true

        return pinView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if oldState == .Ending && !editing {
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

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let pin = view.annotation as? Pin {
            editing ? deletePin(pin) : viewPin(pin)
            mapView.deselectAnnotation(pin, animated: false)
        }
    }
    
    func deletePin(pin: Pin) {
        context.deleteObject(pin)
        context.saveToManagedObjectContext()

        mapView.removeAnnotation(pin)
    }
    
    func viewPin(pin: Pin) {
        let controller = storyboard!.instantiateViewControllerWithIdentifier("CollectionController") as! MapCollectionViewController
        controller.pin = pin
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func createPin(sender: UIGestureRecognizer) {
        if sender.state == .Began {
            let locationCoordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            let pin = Pin(latitude: Double(locationCoordinate.latitude), longitude: Double(locationCoordinate.longitude), context: context)
            pin.flickr?.loadNewPhotosAndAddToPin(context, handler: { _ in
                self.context.saveToManagedObjectContext()
            })
            context.saveToManagedObjectContext()
            
            mapView.addAnnotation(pin)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        hintLabel.hidden = !editing
    }
}
