//
//  LocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/23/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class LocationsMapViewController: UIViewController, NSFetchedResultsControllerDelegate{
    
//    MARK: Map View
    @IBOutlet weak var mapView: MKMapView!
    
//    MARK: Data Controller
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
//    MARK: Parameters
    var isFirstLaunch:Bool!
    var locations = [CLLocationCoordinate2D]()
    
//    MARK: Setup Fetched Results Controller
    fileprivate func setupFetchedResultsController(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "Pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        }catch{
            Logger.log(.error, "The fetch could not be performed: \(error.localizedDescription)")
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
//    MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore"){
            zoomMap()
        }
        
//			Setup Long Press Gesture
//			TODO: Refactor long press gesture into function
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(longPress)

        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        
    }
    
//    MARK: viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        createAnnotations()
    }
    
//    MARK: viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        createAnnotations()
        fetchedResultsController = nil
    }
    
//    MARK: zoomMap
    func zoomMap(){
        let center = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "zoomMapCenterLatitude"), longitude: UserDefaults.standard.double(forKey: "zoomMapCenterLongitude"))
        let span = MKCoordinateSpan(latitudeDelta: UserDefaults.standard.double(forKey: "distanceSpanLatitude"), longitudeDelta: UserDefaults.standard.double(forKey: "distanceSpanLongitude"))
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
//    MARK: didLongPress
    @objc private func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == UIGestureRecognizer.State.began else{
            return
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        annotation.title = ""
        mapView.addAnnotation(annotation)
        
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
        Logger.log(.success, "didLongPress with Coordinates \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
    }
    
//    MARK: createAnnotations
    func createAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for pin in fetchedObjects {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
//    MARK: Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! PhotoAlbumViewController
        let annotation = sender as! MKAnnotation
        viewController.dataController = dataController
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude])
        fetchRequest.predicate = predicate
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            if result.count >= 0{
                viewController.pin = result[0]
            }
        }
        
    }
    
    
}


//MARK: Map View Delegate

extension LocationsMapViewController: MKMapViewDelegate{
    
//    MARK: Map Annotation View
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pin!.canShowCallout = true
            pin!.pinTintColor = .red
            pin!.animatesDrop = true
         } else {
             pin!.annotation = annotation
         }
        
        return pin
    }
    
//    MARK: Map didSelect
    func mapView(_ mapView: MKMapView, didSelect view:  MKAnnotationView){
        print("Coordinate: \(String(describing: view.annotation?.coordinate.latitude)) , \(String(describing: view.annotation?.coordinate.longitude))")
        performSegue(withIdentifier: "seguePhotoAlbum", sender: view.annotation)
    }
    
//    MARK: Map regionDidChangeAnimated
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "zoomMapCenterLatitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "zoomMapCenterLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "distanceSpanLatitude")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "distanceSpanLongitude")
    }
    
}
