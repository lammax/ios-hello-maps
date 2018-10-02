//
//  ViewController.swift
//  hello-maps
//
//  Created by Mac on 01.10.2018.
//  Copyright © 2018 Lammax. All rights reserved.
//

import UIKit
import MapKit
//import CoreLocation



class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapTypeControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView!
    //private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO - make automatical compas positioning 2D/ I'd like to rotate map according to compas.
        // Do any additional setup after loading the view, typically from a nib.
        
        self.mapView.delegate = self
        
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter =  kCLDistanceFilterNone
//
//        locationManager.startUpdatingLocation()
//
        self.mapView.showsUserLocation = true
        
        self.mapTypeControl.addTarget(self, action: #selector(mapTypeChange), for: .valueChanged)
        
        self.addPointOfInterest()
        
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
    
    private func addPointOfInterest() {
        self.mapView.addAnnotation(
            CustomAnnotation(
                title: "Somewhere in USA",
                coordinate: CLLocationCoordinate2D(latitude: 37.334395, longitude: -122.040012))
        )
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
                self.reverseGeocode(address: textFieild.text)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel")
        }
        
        alertVC.addAction(okAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func reverseGeocode(address: String?) {
        
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
            
            self.addPlacemarkToMap(placeMark: placeMark, title: addr)
            
        }
    }
    
    private func addPlacemarkToMap(placeMark: CLPlacemark, title: String) {
        guard let coordinate = placeMark.location?.coordinate else { return }
        self.mapView.addAnnotation(CustomAnnotation(title: title, coordinate: coordinate))
    }
    
}
