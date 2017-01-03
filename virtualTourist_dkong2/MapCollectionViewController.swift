//
//  MapCollectionViewController.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/3/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreData

enum ViewType: String {
    case Scenery
    case Restaurant
}

class MapCollectionViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var hintLabel: UILabel!

    var viewType = ViewType.Scenery
    var viewTypeButton = UIBarButtonItem()
    var pin: Pin!
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    
    
    var businesses: [Business]?
    
    private let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    lazy var fetchedResultsController: NSFetchedResultsController = {
        switch self.viewType {
        case .Scenery:
            if let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "Photo") {
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
                return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: "Photo")
            } else {
                fatalError("Unable to get fetchRequest entity name with Photo!")
            }
        case .Restaurant:
            if let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "Business") {
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
                fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
                return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: "Business")
            } else {
                fatalError("Unable to get fetchRequest entity name with Business!")
            }
        }
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = self.editButtonItem()
        viewTypeButton = UIBarButtonItem.init(image: UIImage(named: "restaurant"), style: .Done, target: self, action: #selector(MapCollectionViewController.loadRestaurants))
        navigationItem.rightBarButtonItems = [viewTypeButton, self.editButtonItem()]

        newCollectionButton.addTarget(self, action: #selector(MapCollectionViewController.loadNewPhotos), forControlEvents: .TouchUpInside)
        hintLabel.text = "Tap to Delete Photo"
        hintLabel.hidden = true
        
        fetchedResultsController.delegate = self
        
        let layout = UICollectionViewFlowLayout()
        let items: CGFloat = view.frame.size.width < view.frame.size.height ? 3 : 5
        let space: CGFloat = 5
        let squareLength = (view.frame.size.width - ((items + 1) * space)) / items
        layout.itemSize = CGSizeMake(squareLength, squareLength)
        layout.minimumLineSpacing = 10.0 - items
        layout.minimumInteritemSpacing = space
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        
        mapView.addAnnotation(pin)
        mapView.userInteractionEnabled = true
        mapView.delegate = self

        mapView.setRegion(MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView
            ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        if annotation.coordinate.latitude == pin.coordinate.latitude && annotation.coordinate.longitude == pin.coordinate.longitude {
            pinView.pinTintColor = UIColor.redColor()
        } else {
            pinView.pinTintColor = UIColor.greenColor()
        }
        
        return pinView
    }
    
    func showAllBusinessPins() -> [Business] {
        return try! (context.executeFetchRequest(NSFetchRequest(entityName: "Business")) as! [Business]) ?? []
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try fetchedResultsController.performFetch()
            if fetchedResultsController.fetchedObjects!.count == 0 {
                loadNewPhotos()
            }
        } catch {
            print("No including a sort descriptor")
        }
    }
    
    func loadNewPhotos() {
        newCollectionButton.enabled = false
        pin.deleteExistingPhotos(context) { _ in
        }
        pin.flickr?.loadNewPhotosAndAddToPin(context, handler: { _ in
            self.newCollectionButton.enabled = true
            self.context.saveToManagedObjectContext()
        })
    }

    func loadRestaurants() {
        switch viewType {
        case .Scenery:
            viewType = .Restaurant
            viewTypeButton.image = UIImage(named: "scenery")
            self.pin.deleteExistingBusinesses(context) { _ in }
            navigationItem.rightBarButtonItems = [viewTypeButton]
            newCollectionButton.setTitle("Click Photo to see details", forState: .Normal)
            newCollectionButton.enabled = false
            
            var max_long = self.pin!.longitude
            var min_long = self.pin!.longitude
            var max_lat = self.pin!.latitude
            var min_lat = self.pin!.latitude
            
            appDelegate.sharedYelpClient?.searchWithLat(Double(pin!.latitude), long: Double(pin!.longitude), term: "restaurant", limit: 20, offset: 0, sort: .Distance) { (businesses: AnyObject?, error: String?) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    guard error == nil else {
                        print("\(error)")
                        return
                    }
                    
                    if let b = businesses as? [NSDictionary] {
                        for businessItem in b {
                            if businessItem is [String: AnyObject] {
                                let item = Business(dictionary: (businessItem as! [String: AnyObject]), pin: self.pin!, context: self.context)
                                max_lat = item.latitude > max_lat ? item.latitude : max_lat
                                min_lat = item.latitude < min_lat ? item.latitude : min_lat
                                max_long = item.longitude > max_long ? item.longitude : max_long
                                min_long = item.longitude < min_long ? item.longitude : min_long
                            }
                        }
                        let center_long = (max_long + min_long)/2
                        let center_lat = (max_lat + min_lat)/2
                        
                        let delta_lat = abs(max_lat - min_lat)
                        let delta_long = abs(max_long - min_long)
                        
                        if self.viewType == .Restaurant {
                            let coord = CLLocationCoordinate2D(latitude: center_lat, longitude: center_long)
                            let span = MKCoordinateSpan(latitudeDelta: delta_lat, longitudeDelta: delta_long)
                            self.mapView.setRegion(MKCoordinateRegion.init(center: coord, span: span), animated: true)
                        }
                        
                    }
                    self.hardProcessingWithString() {
                        self.reloadMapViewAndCollectionView()
                    }
                })
            }
            
        case .Restaurant:
            viewType = .Scenery
            viewTypeButton.image = UIImage(named: "restaurant")
            navigationItem.rightBarButtonItems = [viewTypeButton, self.editButtonItem()]
            newCollectionButton.titleLabel!.text = "New Collection"
            newCollectionButton.enabled = true

            self.hardProcessingWithString() {
                self.reloadMapViewAndCollectionView()
            }
        }
    }
    
    func hardProcessingWithString(completion: (result: Void) -> Void) {
        self.context.saveToManagedObjectContext()
        completion(result: self.reloadMapViewAndCollectionView())
    }
    
    private func reloadMapViewAndCollectionView() {

        let fetchRequest = NSFetchRequest(entityName: "Business")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        businesses = try! (context.executeFetchRequest(fetchRequest) as! [Business]) ?? []

        collectionView.reloadData()

        if viewType == .Restaurant {
            mapView.addAnnotations(showAllBusinessPins())
        } else {
            if let businessesRestaurant: [Business] = showAllBusinessPins() {
                mapView.removeAnnotations(businessesRestaurant)
            }
            mapView.setRegion(MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if viewType == .Restaurant {
            return 1
        }
        return fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewType == .Restaurant {
            return businesses!.count
        }
        return fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if viewType == .Restaurant {
            if  let business: Business = businesses![indexPath.item] {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
                cell.business = business
                return cell
            }
        } else {
            if let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
                cell.photo = photo
                return cell
            } else {
                fatalError("result object is not Photo")
            }
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if editing {
            context.deleteObject(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
            context.saveToManagedObjectContext()
            return
        }
        
        if viewType == .Restaurant {
            let selectedBusiness = businesses![indexPath.item]
            if let name = selectedBusiness.name {
                let rating = selectedBusiness.rating ?? 0.0
                let phone = selectedBusiness.phone ?? ""
                let alert = UIAlertController(title: "\(name)", message: "rating: \(rating) \n Phone: \(phone)",
                                              preferredStyle: .Alert)
                if !phone.isEmpty {
                    alert.addAction(UIAlertAction(title: "Call Restaurant", style: .Default, handler: { action in
                        if let phoneURL = NSURL(string: "tel://\(phone)") where UIApplication.sharedApplication().canOpenURL(phoneURL) {
                            UIApplication.sharedApplication().openURL(phoneURL, options: [:], completionHandler: nil)
                        }
                    }))
                }
                alert.addAction(UIAlertAction(title: "View on Yelp", style: .Default, handler: { action in
                    if let urlString = selectedBusiness.url, let yelpUrl = NSURL(string: urlString) where UIApplication.sharedApplication().canOpenURL(yelpUrl) {
                        UIApplication.sharedApplication().openURL(yelpUrl, options: [:], completionHandler: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        hintLabel.hidden = !editing
    }

}

extension MapCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = []
        deletedIndexPaths = []
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        default:
            return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            _ = self.insertedIndexPaths.map({ self.collectionView.insertItemsAtIndexPaths([$0]) })
            _ = self.deletedIndexPaths.map({ self.collectionView.deleteItemsAtIndexPaths([$0]) })
        }, completion: nil)
    }
}
