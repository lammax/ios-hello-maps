//
//  ViewController.swift
//  hello-maps
//
//  Created by Mac on 01.10.2018.
//  Copyright © 2018 Lammax. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var mapTypeControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    
    private var directionSteps: [MKRoute.Step] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO - make automatical compas positioning 2D/ I'd like to rotate map according to compas.
        // Do any additional setup after loading the view, typically from a nib.
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter =  kCLDistanceFilterNone
        locationManager.startUpdatingLocation()

        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapTypeControl.addTarget(self, action: #selector(mapTypeChange), for: .valueChanged)
        
    }
    
    @objc func mapTypeChange(segmentedControl: UISegmentedControl) {
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            self.mapView.mapType = .standard
        case 1:
            self.mapView.mapType = .satellite
        case 2:
            self.mapView.mapType = .hybrid
        default:
            self.mapView.mapType = .standard
        }
        
    }

    @IBAction func addAnnotationClick(_ sender: UIButton) {
        //CLLocationCoordinate2D(latitude: 55.7525497882909, longitude: 37.6231188699603)
        self.mapView.addAnnotation(
            CustomAnnotation(
                title: "Moscow",
                subtitle: "Kremlin",
                coordinate: self.mapView.userLocation.coordinate
            )
        )
    }
    
    @IBAction func addAddressButtonClick(_ sender: UIButton) {
        let alertVC = UIAlertController(title: "Add address", message: nil, preferredStyle: .alert)
        alertVC.addTextField { (textField) in
            print("Text field")
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if let textFieild = alertVC.textFields?.first {
                //reverse geocode to the address
                self.reverseGeocode(address: textFieild.text, completion: { (placeMark) in
                    let startingMapItem = MKMapItem.forCurrentLocation()
                    let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: (placeMark.location?.coordinate)!))
                    //MKMapItem.openMaps(with: [destinationMapItem], launchOptions: nil) //opens Apple navigator app
                    
                    let directionsRequest = MKDirections.Request()
                    directionsRequest.transportType = .automobile
                    directionsRequest.source = startingMapItem
                    directionsRequest.destination = destinationMapItem
                    
                    let directions = MKDirections(request: directionsRequest)
                    directions.calculate(completionHandler: { (response, error) in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        
                        guard let response = response, let route = response.routes.first else { return }
                        
                        if route.steps.isEmpty {
                            print("No steps in route")
                        } else {
                            self.directionSteps = route.steps
                        }
                        
                        self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                        
                    })
                    
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel")
        }
        
        alertVC.addAction(okAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func searchPOIButtonClick(_ sender: UIButton) {
        let alertVC = UIAlertController(title: "Search POI", message: nil, preferredStyle: .alert)
        alertVC.addTextField { (textField) in
            print("Text field")
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if let textField = alertVC.textFields?.first, let search = textField.text {
                    self.findNearbyPOI(by: search)
                
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel")
        }
        
        alertVC.addAction(okAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }

    private func findNearbyPOI(by searchTerm : String?) {
        
        //TODO: make detach function
        self.mapView.removeAnnotations(self.mapView.annotations) //clear annotations
        self.mapView.removeOverlays(self.mapView.overlays) //clear overlays
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm
        request.region = self.mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let response = response else { return }
            
            for item in response.mapItems {
                self.addPointOfInterest(coordinate: item.placemark.coordinate, title: "\(searchTerm!): \(item.placemark.name!)")
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "showDirectionsTable" {
            let destinationVC = segue.destination as! TableViewController
            destinationVC.delegate = self
        }
    }
    
    @IBAction func directionsButtonClick(_ sender: UIButton) {
        performSegue(withIdentifier: "showDirectionsTable", sender: self)
    }
    
    private func reverseGeocode(address: String?, completion: @escaping (CLPlacemark) -> ()) {
        
        guard let addr = address else {
            print("No address!")
            return
        }

        print(addr)
        
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(addr) { (placeMarks, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let places = placeMarks, let placeMark = places.first else {
                print("No placemark!")
                return
            }
            
            self.addPointOfInterest(coordinate: placeMark.location?.coordinate, title: addr)
            
            //move to address
            self.mapView.setRegion(
                MKCoordinateRegion(center: (placeMark.location?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)),
                animated: true
            )
            
            completion(placeMark)
            
        }
    }
    
    private func addPointOfInterest(coordinate: CLLocationCoordinate2D?, title: String?) {
        let annotation = CustomAnnotation(
            title: title,
            coordinate: coordinate
        )
        
        self.mapView.addAnnotation(annotation)
        
        //start to monitor region
        //add region for monitoring
        let region = CLCircularRegion(center: annotation.coordinate, radius: 100.0, identifier: title!)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        addFancyRegion(annotation: annotation)
        
        self.locationManager.startMonitoring(for: region)
        
    }
    
    private func addFancyRegion(annotation: CustomAnnotation) {
        self.mapView.addOverlay(MKCircle(center: annotation.coordinate, radius: 100)) //1000 meters
    }
    
    private func popOKAlert(title: String?) {
        let alertVC = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            print("OK")
        }
        
        alertVC.addAction(okAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
    
}

extension ViewController: DirectionsTableDelegate {
    func getDirectionSteps() -> [MKRoute.Step] {
        return self.directionSteps
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        showNotification(title: "Enter", message: "Enter region \(region.identifier)")
        popOKAlert(title: "Pop Enter region \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        showNotification(title: "Exit", message: "Exit region \(region.identifier)")
        popOKAlert(title: "Pop Exit region \(region.identifier)")
    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        //print(overlay.title)
        
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.purple
            circleRenderer.fillColor = UIColor.white
            circleRenderer.alpha = 0.5
            return circleRenderer
        }
        
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            polylineRenderer.lineWidth = 3.0
            polylineRenderer.strokeColor = UIColor.purple
            polylineRenderer.fillColor = UIColor.white
            polylineRenderer.alpha = 0.5
            return polylineRenderer
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        var customAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotationView")
        
        if customAnnotationView == nil {
            customAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotationView")
            customAnnotationView?.canShowCallout = false
        } else {
            customAnnotationView?.annotation = annotation
        }
        
        if let customAnnotation = annotation as? CustomAnnotation {
            customAnnotationView?.image = UIImage(named: customAnnotation.imageURL)
        }
        
        return customAnnotationView
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        view.subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation as? CustomAnnotation else {
            return
        }
        
        //create custom callout
        CustomCalloutView(annotation: annotation).add(to: view)
        
    }
    
}
