//
//  CustomAnnotation.swift
//  hello-maps
//
//  Created by Mac on 01.10.2018.
//  Copyright © 2018 Lammax. All rights reserved.
//

import MapKit

class CustomAnnotation: MKPointAnnotation {
    var imageURL: String!
    
    init(imageURL: String = "custom_geotag", title: String? = nil, subtitle: String? = nil, coordinate: CLLocationCoordinate2D? = nil) {
        super.init()
        self.imageURL = imageURL
        self.title = title
        self.subtitle = subtitle
        if let coord = coordinate {
            self.coordinate = coord
        }
    }
    
}
