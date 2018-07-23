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
    private var currentLocation: CLLocation?
    private var lastUpdateTime: Date?
    
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
        
        // Initialize time
        lastUpdateTime = Date()
        
        // Location Manager code to fetch current location
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()

        // Location Manager background code
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    @IBAction func recenter(_ sender: UIButton) {
        cameraMoveToLocation(toLocation: currentLocation?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLoc = locations.last else { return }
        currentLocation = currentLoc
        
        let currentTime = currentLocation!.timestamp
        let currentTimeDifference = currentLocation!.timestamp.timeIntervalSince(lastUpdateTime!)
        
        // Initial Recenter
        if !initialRecenterDone {
            cameraMoveToLocation(toLocation: currentLocation?.coordinate)
            initialRecenterDone = true
        }
        
        // Upload data
        if (UIApplication.shared.applicationState == .active) && (currentTimeDifference > CONSTANTS.TIME.MinimumTimeInterval)
        {
            uploadLocation(location: currentLoc)
            lastUpdateTime = currentTime
        }
    }
    
    func cameraMoveToLocation(toLocation: CLLocationCoordinate2D?) {
        if toLocation != nil {
            self.mapView.camera = GMSCameraPosition.camera(withTarget: toLocation!, zoom: 17)
        }
    }
    
    func uploadLocation(location: CLLocation) {
//        print("Uploading Location: %@", currentLocation!)
//        print("Time: %@", location.timestamp.description)
//        let df = DateFormatter()
//        df.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"
//        let date = df.date(from: location.timestamp.description)
//        print("Time: %@", date!.description)
//        df.timeZone = TimeZone.current
//        print("Local Time: %@", df.string(from: date!))
        
        db.collection(CONSTANTS.DATA.User).document(location.timestamp.description).setData([
            CONSTANTS.DATA.Latitude: location.coordinate.latitude,
            CONSTANTS.DATA.Longitude: location.coordinate.longitude
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document successfully written")
            }
        }
    }

    
}


