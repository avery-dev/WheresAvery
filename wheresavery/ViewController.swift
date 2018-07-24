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
    private var datePicker: UIDatePicker?
    
    // UI components
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var recenterButton: UIButton!
    @IBOutlet weak var timeContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Firebase initialization
        db = Firestore.firestore()

        /* PLAYGROUND */
        let start = Calendar.current.date(
            bySettingHour: 0,
            minute: 0,
            second: 0,
            of: Date())!
        let end = start.addingTimeInterval(86400)
        db.collection("Avery")
            .whereField("timestamp", isGreaterThan: start)
            .whereField("timestamp", isLessThan: end)
            .getDocuments() {
                querySnapshot, error in
                if let error = error {
                    print("\(error.localizedDescription )")
                } else {
                    for document in (querySnapshot?.documents)! {
                        print(document.data())
                    }
                }
        }
        /* PLAYGROUND END */ 
        
        // UI
        InitializeUIComponents()
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
    
    func InitializeUIComponents() {
        // Recenter Button
        recenterButton.layer.masksToBounds = false
        recenterButton.layer.cornerRadius = 25
        self.view.addSubview(recenterButton)
        
        timeContainer.layer.cornerRadius = 10
        self.view.addSubview(timeContainer)
    }
    
    @IBAction func recenter(_ sender: UIButton) {
        cameraMoveToLocation(toLocation: currentLocation?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLoc = locations.last else { return }
        currentLocation = currentLoc
        
        // Initial Recenter
        if !initialRecenterDone {
            cameraMoveToLocation(toLocation: currentLocation?.coordinate)
            uploadLocation(location: currentLoc)
            initialRecenterDone = true
        }
        
        let currentTime = currentLocation!.timestamp
        let currentTimeDifference = currentLocation!.timestamp.timeIntervalSince(lastUpdateTime!)
        // Upload data
        if (UIApplication.shared.applicationState == .active) && (currentTimeDifference > CONSTANTS.TIME.MinimumTimeInterval)
        {
            uploadLocation(location: currentLoc)
            lastUpdateTime = currentTime
        }
    }
    
    func cameraMoveToLocation(toLocation: CLLocationCoordinate2D?) {
        if toLocation != nil {
            self.mapView.animate(to: GMSCameraPosition.camera(withTarget: toLocation!, zoom: 17))
        }
    }
    
    func uploadLocation(location: CLLocation) {
        db.collection(CONSTANTS.DATA.User).document(location.timestamp.description).setData([
            CONSTANTS.DATA.Latitude: location.coordinate.latitude,
            CONSTANTS.DATA.Longitude: location.coordinate.longitude,
            CONSTANTS.DATA.Timestamp: location.timestamp
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document successfully written")
            }
        }
    }

    
}


