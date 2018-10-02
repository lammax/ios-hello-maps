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



class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapTypeControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO - make automatical compas positioning 2D/ I'd like to rotate map according to compas.
        // Do any additional setup after loading the view, typically from a nib.
        
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.purple
            circleRenderer.fillColor = UIColor.white
            circleRenderer.alpha = 0.5
            return circleRenderer
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
    
    /*func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        mapView.setRegion(region, animated: true)
    }*/

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
                    let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: (placeMark.location?.coordinate)!))
                    MKMapItem.openMaps(with: [destinationMapItem], launchOptions: nil)
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
        let region = CLCircularRegion(center: annotation.coordinate, radius: 500.0, identifier: "Region1")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        addFancyRegion(annotation: annotation)
        
        self.locationManager.startMonitoring(for: region)
        
    }
    
    private func addFancyRegion(annotation: CustomAnnotation) {
        self.mapView.addOverlay(MKCircle(center: annotation.coordinate, radius: 500)) //1000 meters
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        popOKAlert(title: "Enter region \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        popOKAlert(title: "Exit region \(region.identifier)")
    }
    
    private func popOKAlert(title: String?) {
        let alertVC = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        
        alertVC.addAction(okAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
}
