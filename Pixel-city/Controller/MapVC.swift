//
//  MapVC.swift
//  Pixel-city
//
//  Created by Nan on 2018/2/5.
//  Copyright © 2018年 nan. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {
    
    // Outlets
    @IBOutlet weak var mapView:
    MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
    }
    
}

extension MapVC: MKMapViewDelegate {
    
}
