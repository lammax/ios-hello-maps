//
//  CustomCalloutView.swift
//  hello-maps
//
//  Created by Mac on 02.10.2018.
//  Copyright © 2018 Lammax. All rights reserved.
//

import Foundation
import UIKit

class CustomCalloutView: UIView {
    
    private var annotation: CustomAnnotation!
    
    init(annotation: CustomAnnotation, frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.annotation = annotation
        configure()
    }
    
    private func configure() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor(displayP3Red: 55/255, green: 152/255, blue: 219/255, alpha: 1.0)

        addTitle()
    }
    
    func add(to view: UIView) {
        view.addSubview(self)
        self.bottomAnchor.constraint(equalTo: view.topAnchor, constant: -5) .isActive = true
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    }
    
    func addTitle() {

        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.textColor = UIColor.white
        titleLabel.text = self.annotation.title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.sizeToFit()

        let labelSize = titleLabel.frame.size
        self.widthAnchor.constraint(equalToConstant: labelSize.width).isActive = true
        self.heightAnchor.constraint(equalToConstant: labelSize.height).isActive = true

        self.addSubview(titleLabel)

        titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
