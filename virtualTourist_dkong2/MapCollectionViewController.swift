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

let kNoRestaurantFound = "No nearby restaurants found."
let kNoPhotoFound = "No nearby photos found."

class MapCollectionViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var hintLabel: UILabel!

    var mapType: MKMapType!
    var viewType = ViewType.Scenery
    var viewTypeButton = UIBarButtonItem()
    var pin: Pin!
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    
    
    var businesses: [Business]?
    
    private let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        let fetchRequest: NSFetchRequest<Photo> = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: "Photo")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = self.editButtonItem
        viewTypeButton = UIBarButtonItem.init(image: UIImage(named: "restaurant"), style: .done, target: self, action: #selector(MapCollectionViewController.loadRestaurants))
        navigationItem.rightBarButtonItems = [viewTypeButton, self.editButtonItem]

        newCollectionButton.addTarget(self, action: #selector(MapCollectionViewController.loadNewPhotos), for: .touchUpInside)
        
        fetchedResultsController.delegate = self
        
        let layout = UICollectionViewFlowLayout()
        let items: CGFloat = view.frame.size.width < view.frame.size.height ? 3 : 5
        let space: CGFloat = 5
        let squareLength = (view.frame.size.width - ((items + 1) * space)) / items
        layout.itemSize = CGSize(width: squareLength, height: squareLength)
        layout.minimumLineSpacing = 10.0 - items
        layout.minimumInteritemSpacing = space
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        
        mapView.addAnnotation(pin)
        mapView.isUserInteractionEnabled = true
        mapView.mapType = mapType
        mapView.delegate = self

        mapView.setRegion(MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkLocalPhotos()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
            ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        if annotation.coordinate.latitude == pin.coordinate.latitude && annotation.coordinate.longitude == pin.coordinate.longitude {
            pinView.pinTintColor = UIColor.red
        } else {
            pinView.pinTintColor = UIColor.green
        }
        
        return pinView
    }
    
    func showAllBusinessPins() -> [Business] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Business")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        return try! (context.fetch(fetchRequest) as! [Business]) 
    }
    
    func loadNewPhotos() {
        if Reachability.isConnectedToNetwork() != .notReachable {
            newCollectionButton.isEnabled = false
            pin.deleteExistingPhotos(context) { _ in }
            pin.flickr?.loadNewPhotosAndAddToPin(context, handler: { (error: String?) in
                if error == "HTTP Errors" {
                    super.showConnectionAlertView(error)
                }
                self.hintLabel.isHidden = true
                self.newCollectionButton.isEnabled = true
                self.context.saveToManagedObjectContext()
            })
        } else {
            super.showConnectionAlertView()
            hintLabel.text = kNoPhotoFound
        }
    }

    func loadRestaurants() {
        switch viewType {
        case .Scenery:
            viewType = .Restaurant
            viewTypeButton.image = UIImage(named: "scenery")
            navigationItem.rightBarButtonItems = [viewTypeButton]
            newCollectionButton.setTitle("Click Photo to see details", for: .normal)
            newCollectionButton.isEnabled = false
            
            if Reachability.isConnectedToNetwork() != .notReachable {
                self.pin.deleteExistingBusinesses(context) { _ in }
                if let sharedYelpClient = appDelegate.sharedYelpClient {
                    sharedYelpClient.searchWithLat(Double(pin!.latitude), long: Double(pin!.longitude), term: "restaurant", limit: 20, offset: 0, sort: .Distance) { (businesses: AnyObject?, error: String?) -> Void in
                        DispatchQueue.main.async{
                            guard error == nil else {
                                super.showConnectionAlertView(error)
                                return
                            }
                            self.calculateMapViewRegion(businesses: businesses)
                            self.saveToCoreDataAndUpdateUI() {}
                        }
                    }
                } else {
                    // If appDelegate.sharedYelpClient is nil, do OAuth first, then send search request
                    let yelp = YelpClientAPI()
                    
                    yelp.authWithAppID("JGAl29kTR_1GNRPnj8XZzA", secret: "SFHjUh3LX2ORlOoHIgIHhCeS1UIHnYZvjxBvMx5R3kptLt1LzXM44qptycMfksIP", completionHandler: {(client: YelpClientAPI?, error: String?) -> Void in
                        guard error == nil else {
                            if error == "HTTP Errors" {
                                super.showConnectionAlertView(error)
                            }
                            return
                        }
                        self.appDelegate.yelpClient = client!
                        
                        if (client == nil) {
                            print("Authentication failed: \(error)")
                        }
                        
                        self.appDelegate.yelpClient!.searchWithLat(Double(self.pin!.latitude), long: Double(self.pin!.longitude), term: "restaurant", limit: 20, offset: 0, sort: .Distance) { (businesses: AnyObject?, error: String?) -> Void in
                            DispatchQueue.main.async {
                                guard error == nil else {
                                    super.showConnectionAlertView(error)
                                    return
                                }
                                
                                self.calculateMapViewRegion(businesses: businesses)
                                self.saveToCoreDataAndUpdateUI() {
                                }
                            }
                        }
                    })
                }
                
            } else {
                super.showConnectionAlertView()
                businesses = showAllBusinessPins()
                
                if businesses?.count != 0 {
                    calculateMapViewRegion(businesses: businesses as AnyObject?)
                    saveToCoreDataAndUpdateUI() { }
                } else {
                    hintLabel.isHidden = false
                    hintLabel.text = kNoRestaurantFound
                    saveToCoreDataAndUpdateUI() { }
                }
            }
            
        case .Restaurant:
            viewType = .Scenery
            viewTypeButton.image = UIImage(named: "restaurant")
            navigationItem.rightBarButtonItems = [viewTypeButton, self.editButtonItem]
            newCollectionButton.setTitle("New Collection", for: .normal)
            newCollectionButton.isEnabled = true
            hintLabel.text = ""
            
            checkLocalPhotos()
            saveToCoreDataAndUpdateUI() { }
        }
    }
    
    func calculateMapViewRegion(businesses: AnyObject? = nil) {
        var max_long = self.pin!.longitude
        var min_long = self.pin!.longitude
        var max_lat = self.pin!.latitude
        var min_lat = self.pin!.latitude
        
        if let temp = businesses as? [Business] {
            for item in temp {
                max_lat = item.latitude > max_lat ? item.latitude : max_lat
                min_lat = item.latitude < min_lat ? item.latitude : min_lat
                max_long = item.longitude > max_long ? item.longitude : max_long
                min_long = item.longitude < min_long ? item.longitude : min_long
            }
        } else if let dict = businesses as? [NSDictionary] {
            for businessItem in dict {
                if businessItem is [String: AnyObject] {
                    let item = Business(dictionary: (businessItem as! [String: AnyObject]), pin: self.pin!, context: self.context)
                    max_lat = item.latitude > max_lat ? item.latitude : max_lat
                    min_lat = item.latitude < min_lat ? item.latitude : min_lat
                    max_long = item.longitude > max_long ? item.longitude : max_long
                    min_long = item.longitude < min_long ? item.longitude : min_long
                }
            }
        }

        let center_long = (max_long + min_long)/2
        let center_lat = (max_lat + min_lat)/2
        
        let delta_lat = abs(max_lat - min_lat)
        let delta_long = abs(max_long - min_long)
        
        let coord = CLLocationCoordinate2D(latitude: center_lat, longitude: center_long)
        let span = MKCoordinateSpan(latitudeDelta: delta_lat, longitudeDelta: delta_long)
        self.mapView.setRegion(MKCoordinateRegion.init(center: coord, span: span), animated: true)
    }
    
    func checkLocalPhotos() {
        do {
            try fetchedResultsController.performFetch()
            
            if fetchedResultsController.fetchedObjects!.count == 0 {
                loadNewPhotos()
            }
        } catch {
            print("No including a sort descriptor")
        }
    }
    
    func saveToCoreDataAndUpdateUI(completion: (_ result: Void) -> Void) {
        self.context.saveToManagedObjectContext()
        completion(self.reloadMapViewAndCollectionView())
    }
    
    private func reloadMapViewAndCollectionView() {
        businesses = showAllBusinessPins()
        collectionView.reloadData()


        
        if viewType == .Restaurant {
            mapView.addAnnotations(businesses!)
            if businesses!.count == 0 {
                hintLabel.isHidden = false
                hintLabel.text = kNoRestaurantFound
            } else {
                hintLabel.isHidden = true
            }
        } else {
            mapView.removeAnnotations(showAllBusinessPins())
            mapView.setRegion(MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
            if let fetchedResults = fetchedResultsController.fetchedObjects {
                if fetchedResults.count == 0 {
                    hintLabel.isHidden = false
                    hintLabel.text = kNoPhotoFound
                } else {
                    hintLabel.isHidden = true
                }
            }

        }
    }
    
    private func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if viewType == .Restaurant {
            return 1
        }
        return fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewType == .Restaurant {
            if let businesses = businesses {
                return businesses.count
            } else {
                return 0
            }
        }
        return fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewType == .Restaurant {
            if businesses != nil {
                if  let business: Business = businesses?[indexPath.item] {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath as IndexPath) as! PhotoCollectionViewCell
                    cell.business = business
                    return cell
                }
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath as IndexPath) as! PhotoCollectionViewCell
                return cell
            }
        } else {
            let photo: Photo = fetchedResultsController.object(at: indexPath)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath as IndexPath) as! PhotoCollectionViewCell
            cell.photo = photo
            return cell
        }
        fatalError("Return an unknown cell. Should never goes here!")
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            context.delete(fetchedResultsController.object(at: indexPath))
            context.saveToManagedObjectContext()
            return
        }
        
        if viewType == .Restaurant {
            let selectedBusiness = businesses![indexPath.item]
            if let name = selectedBusiness.name {
                let rating = selectedBusiness.rating 
                let phone = selectedBusiness.phone ?? ""
                let alert = UIAlertController(title: "\(name)", message: "rating: \(rating) \n Phone: \(phone)",
                                              preferredStyle: .alert)
                if !phone.isEmpty {
                    alert.addAction(UIAlertAction(title: "Call Restaurant", style: .default, handler: { action in
                        if let phoneURL = NSURL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(phoneURL as URL) {
                            UIApplication.shared.open(phoneURL as URL, options: [:], completionHandler: nil)
                        }
                    }))
                }
                alert.addAction(UIAlertAction(title: "View on Yelp", style: .default, handler: { action in
                    if let urlString = selectedBusiness.url, let yelpUrl = NSURL(string: urlString), UIApplication.shared.canOpenURL(yelpUrl as URL) {
                        UIApplication.shared.open(yelpUrl as URL, options: [:], completionHandler: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if viewType == .Scenery {
            newCollectionButton.setTitle(editing ? "Click Photo to delete" : "new Collection", for: .normal)
        } else {
            newCollectionButton.setTitle(editing ? "Click Photo to see details" : "new Collection", for: .normal)
        }
        newCollectionButton.isEnabled = !editing
    }

}

extension MapCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = []
        deletedIndexPaths = []
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath! as NSIndexPath)
        case .delete:
            deletedIndexPaths.append(indexPath! as NSIndexPath)
        default:
            return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            _ = self.insertedIndexPaths.map({ self.collectionView.insertItems(at: [$0 as IndexPath]) })
            _ = self.deletedIndexPaths.map({ self.collectionView.deleteItems(at: [$0 as IndexPath]) })
        }, completion: nil)
    }
}
