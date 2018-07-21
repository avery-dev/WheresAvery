//
//  ViewController.swift
//  wheresavery
//
//  Created by Avery Ni on 7/21/18.
//  Copyright © 2018 Avery Ni. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @IBOutlet var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view = mapView
        self.mapView?.isMyLocationEnabled = true
        
        //Location Manager code to fetch current location
        self.locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locationManager.location?.coordinate
        cameraMoveToLocation(toLocation: location)
    }
    
    func cameraMoveToLocation(toLocation: CLLocationCoordinate2D?) {
        if toLocation != nil {
            self.mapView.camera = GMSCameraPosition.camera(withTarget: toLocation!, zoom: 17)
        }
    }

}


