//
//  ViewController.swift
//  wheresavery
//
//  Created by Avery Ni on 7/21/18.
//  Copyright © 2018 Avery Ni. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

class ViewController: UIViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var db: Firestore!
    private var initialRecenterDone = false
    private var currentLocation: CLLocationCoordinate2D?
    
    // UI components
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var recenterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Firebase initialization
        db = Firestore.firestore()
        
        // UI
        self.view.addSubview(recenterButton)
        self.view = mapView
        self.mapView?.isMyLocationEnabled = true
        
        // Location Manager code to fetch current location
        self.locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    @IBAction func recenter(_ sender: UIButton) {
        cameraMoveToLocation(toLocation: currentLocation)
        
        // Add a new document with a generated ID
        /*
        var ref: DocumentReference? = nil
        ref = db.collection("users").addDocument(data: [
            "first": "Avery",
            "last": "Ni",
            "born": 1995
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }*/
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


