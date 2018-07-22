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
    @IBOutlet weak var recenterButton: UIButton!
    private var initialRecenterDone = false
    private var currentLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(recenterButton)
        
        self.view = mapView
        self.mapView?.isMyLocationEnabled = true
        
        //Location Manager code to fetch current location
        self.locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    @IBAction func recenter(_ sender: UIButton) {
        cameraMoveToLocation(toLocation: currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locationManager.location?.coordinate
        if (!initialRecenterDone) {
            cameraMoveToLocation(toLocation: currentLocation)
            initialRecenterDone = true
        }
    }
    
    func cameraMoveToLocation(toLocation: CLLocationCoordinate2D?) {
        if toLocation != nil {
            self.mapView.camera = GMSCameraPosition.camera(withTarget: toLocation!, zoom: 17)
        }
    }

    
}


