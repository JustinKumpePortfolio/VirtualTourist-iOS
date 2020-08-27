//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Justin Kumpe on 8/16/20.
//  Copyright © 2020 Justin Kumpe. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController {
    
//    MARK: Views
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
//    MARK: Flow Layout
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    
//    MARK: Variables
    var pin: Pin!
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var page: Int = 1
    var blockOperations: [BlockOperation] = []
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: pin))-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            Logger.log(.error, "The fetch could not be performed: \(error.localizedDescription)")
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        setupMap()
        setupCollectionView()
        if let fetchedPhotos = fetchedResultsController.fetchedObjects {
            if fetchedPhotos.count == 0 {
                grabPhotosList(page: page)
            }
        }
        
//        Sets image count to a larger number if running on an iPad
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            FlickrClient.Endpoints.perPage = "50"
        default:
            FlickrClient.Endpoints.perPage = "25"
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
//    MARK: setupMap
//    Drops Pin on Map
    func setupMap() {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)), animated: true)
    }
    
//    MARK: setupCollectionView
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        flowLayout.minimumInteritemSpacing = 3.0
        flowLayout.minimumLineSpacing = 3.0
    }
    
//    MARK: grabPhotosList
//    Grabs list of photos from Flickr
    func grabPhotosList(page: Int){
        
        FlickrClient.searchPhotos(lat: pin.latitude, long: pin.longitude, page: page, completion: handleSearchResponse(FlickrPhotosResponse:error:))
    }

//    MARK: handleSearchResponse
    func handleSearchResponse(FlickrPhotosResponse: FlickrPhotosResponse?, error: Error?){
        
        guard let photosResponse = FlickrPhotosResponse else {
            return
        }
        
        if photosResponse.photos.photo.count == 0{
            Logger.log(.warning, "No images were found")
            ShowAlert.error(viewController: self, title: "No Images", message: "No images were found for this location.")
        }else{
            for _ in photosResponse.photos.photo{
                let photo = Photo(context: dataController.viewContext)
                photo.image = UIImage.init(imageLiteralResourceName: "no-image").jpegData(compressionQuality: 1.0)
                photo.pin = pin
                photo.creationDate = Date()
                try? dataController.viewContext.save()
            }
            
        }
        dispatchOnBackground {
            self.downloadPhotoImages(photos: photosResponse.photos.photo)
        }
    }
    
    func downloadPhotoImages(photos: [FlickrPhoto]){
        var i = 0
        for photo in photos {
            let url = FlickrClient.Endpoints.download(photo.farm, photo.server, photo.id, photo.secret).url
            FlickrClient.downloadImage(url: url, index: i, completionHandler: handleImageDownloadResponse(image:error:index:))
            i += 1
        }
    }
    
//    MARK: handleImageDownloadResponse
    func handleImageDownloadResponse(image: UIImage?, error: Error?, index: Int){
        guard let image = image else{
            Logger.log(.error, "Image Var NIL")
            return
        }
        
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else{
            Logger.log(.error, "Fetched Objects NIL")
            return
        }
        
        fetchedObjects[index].image = image.jpegData(compressionQuality: 1.0)
        try? dataController.viewContext.save()
        
        dispatchOnMain {
            self.collectionView.reloadData()
        }
    }
    
//    MARK: deleteImage
    func deletePhoto(indexPath: IndexPath){
        Logger.log(.action, "Delete Photo at \(indexPath)")
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
//    MARK: newCollectionPressed
    @IBAction func newCollectionPressed(sender: Any){
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for fetchedObject in fetchedObjects {
                dataController.viewContext.delete(fetchedObject)
            }
            try? dataController.viewContext.save()
        }
        page += 1
        grabPhotosList(page: page)
    }
}

//MARK: FetchedResultsControllerDelegate
extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () -> Void in
            for blockOperation in self.blockOperations {
                blockOperation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
       
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
            break
        case .delete:
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                        
                    }
                })
            )
            break
        case .update:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
            break
        case .move:
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
            break
        @unknown default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        @unknown default:
            break
        }
    }
    
}

//MARK: Map View Delegates
extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let myPinIdentifier = "PinAnnotationIdentifier"
        let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
        myPinView.animatesDrop = true
        myPinView.canShowCallout = true
        myPinView.annotation = annotation
        return myPinView
    }
}

//MARK: Collection View Delegates
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
//    MARK: numberOfSections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
//    MARK: collectionView numberOfItemsInSection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
//    MARK: collectionView cellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCollectionViewCell
        cell.imageView.image = UIImage(data: photo.image!)
        return cell
    }
    
//    MARK: collectionView didSelectItemAt
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ShowAlert.alertDestructive(viewController: self, title: "Delete Image", message: "Would you like to delete this image?", okButton: "Yes", cancelbutton: "No"){
            confirm in
            Logger.log(.success, confirm)
            Logger.log(.success, indexPath)
            if confirm{
                self.deletePhoto(indexPath: indexPath)
            }
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.size.width
        let columns:CGFloat = 3.0
        let dimension = (width - ((columns - 1) * 3.0)) / columns
        return CGSize(width: dimension, height: dimension * 0.9)
    }

}
