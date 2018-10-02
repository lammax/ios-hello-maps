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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        var customAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "CustomAnnotationView") as? MKAnnotationView
        
        if customAnnotationView == nil {
            customAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "CustomAnnotationView")
            //customAnnotationView?.glyphText = "😎"
            //customAnnotationView?.markerTintColor = UIColor.black
            //customAnnotationView?.glyphImage = UIImage(named: "custom_geotag")
            customAnnotationView?.canShowCallout = true
            
            configureAnnotationView(customAnnotationView!)
            
        } else {
            customAnnotationView?.annotation = annotation
        }
        
        if let customAnnotation = annotation as? CustomAnnotation {
            customAnnotationView?.image = UIImage(named: customAnnotation.imageURL)
        }
        
        return customAnnotationView
        
    }
    
    private func configureAnnotationView(_ annotation : MKAnnotationView) {
        
//        let view = UIView(frame: CGRect.zero )
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.widthAnchor.constraint(equalToConstant:  200).isActive = true
//        view.heightAnchor.constraint(equalToConstant:  200).isActive = true
//        view.backgroundColor = UIColor.red
//        annotation.leftCalloutAccessoryView = UIImageView(image: UIImage(named: "custom_geotag")) as UIView
//        annotation.rightCalloutAccessoryView = UIImageView(image: UIImage(named: "custom_geotag")) as UIView
//        annotation.detailCalloutAccessoryView = view
        
        let snapShotSize = CGSize(width: 200, height: 300)
        
        let snapShotView = UIView(frame: CGRect.zero )
        snapShotView .translatesAutoresizingMaskIntoConstraints = false
        snapShotView.widthAnchor.constraint(equalToConstant:  snapShotSize.width).isActive = true
        snapShotView.heightAnchor.constraint(equalToConstant:  snapShotSize.height).isActive = true
        let options = MKMapSnapshotter.Options()
        options.size = snapShotSize
        options.mapType = .satelliteFlyover
        options.camera = MKMapCamera(lookingAtCenter: (annotation.annotation?.coordinate)! , fromDistance: 10, pitch: 65, heading: 0)
        
        let snapShotter = MKMapSnapshotter(options: options)
        snapShotter.start { (snapShot, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let snapshot = snapShot {
                let imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: snapShotSize))
                imageView.image = snapshot.image
                snapShotView.addSubview(imageView)
            }
            
        }
        
        annotation.detailCalloutAccessoryView = snapShotView

        
    }
    
    /*func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        mapView.setRegion(region, animated: true)
    }*/

    @IBAction func addAnnotationClick(_ sender: UIButton) {
        let annotation = CustomAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 55.7525497882909, longitude: 37.6231188699603)
            //self.mapView.userLocation.coordinate
        annotation.title = "Moscow"
        annotation.subtitle = "Kremlin"
        annotation.imageURL = "custom_geotag"
        self.mapView.addAnnotation(annotation)
    }
    
}

