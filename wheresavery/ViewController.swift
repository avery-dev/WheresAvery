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
    private var initialRecenterDone = false
    private var currentLocation: CLLocation?
    private var lastUpdateTime: Date? // Last UI Map Upload Time
    private var dateFormatter: DateFormatter?
    private var timeFormatter: DateFormatter?
    private var datePicker: UIDatePicker?
    private var breadcrumbManager: BreadcrumbManager?
    private var breadcrumbKeys: [String]?
    
    
    // UI components
    @IBOutlet weak var mapViewContainer: UIView!
    @IBOutlet weak var recenterButton: UIButton!
    @IBOutlet weak var timeContainer: UIView!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var timeSlider: UISlider!
    var toolbar:UIToolbar?
    
    private var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Firebase initialization
        breadcrumbManager = BreadcrumbManager()
        breadcrumbManager?.retrieveBreadcrumbsFromDate(date: Date()) {
            self.locationManager.startUpdatingLocation()
        }
        
        // Date-Time Formatter initialization
        dateFormatter = DateFormatter()
        dateFormatter?.dateFormat = "MM/dd/yyyy"
        timeFormatter = DateFormatter()
        timeFormatter?.dateFormat = "hh:mm"
        
        // UI
        InitializeUIComponents()
        
        // Initialize time
        lastUpdateTime = Date()
        
        // Location Manager code to fetch current location
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()

        // Location Manager background code
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
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
            //uploadLocation(location: currentLoc)
            lastUpdateTime = currentTime
        }
    }
    
    func cameraMoveToLocation(toLocation: CLLocationCoordinate2D?, zoom: Float = 17, animate: Bool = true) {
        if toLocation != nil {
            if animate {
                self.mapView.animate(to: GMSCameraPosition.camera(withTarget: toLocation!, zoom: zoom))
            } else {
                self.mapView.camera = GMSCameraPosition.camera(withTarget: toLocation!, zoom: 17)
            }
        }
    }
    
    func uploadLocation(location: CLLocation) {
        breadcrumbManager?.uploadBreadcrumb(breadcrumb: Breadcrumb(dictionary: [
            CONSTANTS.DATA.Latitude: location.coordinate.latitude,
            CONSTANTS.DATA.Longitude: location.coordinate.longitude,
            CONSTANTS.DATA.Timestamp: location.timestamp
        ])!)
    }
    
    // UI CODE
    func InitializeUIComponents() {
        mapView = GMSMapView(frame: self.mapViewContainer.frame)
        mapView?.isMyLocationEnabled = true
        self.view.addSubview(mapView)
        
        // Recenter Button
        recenterButton.layer.masksToBounds = false
        recenterButton.layer.cornerRadius = 25
        view.bringSubview(toFront: recenterButton)
        
        // Time Container Panel
        timeContainer.layer.cornerRadius = 10
        
        // Date Picking
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .date
        datePicker?.maximumDate = Date()
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        
        let cancelButton = UIBarButtonItem(title: "Cancel",
                                           style: UIBarButtonItemStyle.plain,
                                           target: self,
                                           action: #selector(ViewController.dateCancelled))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: UIBarButtonItemStyle.plain,
                                         target: self,
                                         action: #selector(ViewController.datePicked))
        toolBar.setItems([cancelButton, space, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        
        dateField.inputAccessoryView = toolBar
        dateField.inputView = datePicker
        dateField.text = dateFormatter?.string(from: Date())
        
        view.bringSubview(toFront: timeContainer)
    }
    
    func regenerateSlider(dateId: String) {
        breadcrumbKeys = breadcrumbManager?.getBreadcrumbsFromDateId(dateId: dateId).keys.sorted()
        timeSlider.maximumValue = Float((breadcrumbKeys?.count)! - 1)
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        timeSlider.value = roundf(sender.value)
        let breadcrumbKeysIndex = Int(timeSlider.value)
        let dateId = dateField.text
        let breadcrumb = breadcrumbManager?.getBreadcrumbsFromDateId(dateId: dateId!)[breadcrumbKeys![breadcrumbKeysIndex]]
        let toLocation = CLLocationCoordinate2D(latitude: (breadcrumb?.latitude)!, longitude: (breadcrumb?.longitude)!)
        cameraMoveToLocation(toLocation: toLocation, animate: false)
    }
    
    @objc func datePicked() {
        let dateId = dateFormatter?.string(from: datePicker!.date)
        dateField.text = dateId
        breadcrumbManager?.retrieveBreadcrumbsFromDate(date: datePicker!.date) {
            let breadcrumbs = self.breadcrumbManager?.getBreadcrumbsFromDateId(dateId: dateId!)
            if (breadcrumbs == nil) {
                // This should never happen unless internet shits out?
            } else {
                self.mapView.clear()
                var averageLat = 0.0
                var averageLong = 0.0
                // Drop a pin everywhere I was
                for data in (breadcrumbs)! {
                    let breadcrumb = data.value
                    let position = CLLocationCoordinate2D(latitude: breadcrumb.latitude, longitude: breadcrumb.longitude)
                    averageLat += breadcrumb.latitude
                    averageLong += breadcrumb.longitude
                    
                    let marker = GMSMarker(position: position)
                    marker.title = data.key
                    marker.map = self.mapView
                }
                averageLat /= Double((breadcrumbs?.count)!)
                averageLong /= Double((breadcrumbs?.count)!)
                let camera = CLLocationCoordinate2D(latitude: averageLat, longitude: averageLong)
                self.cameraMoveToLocation(toLocation: camera, zoom: 15)
                
                self.regenerateSlider(dateId: dateId!)
                
            }
        }
        view.endEditing(true)
    }
    
    @objc func dateCancelled() {
        view.endEditing(true)
    }
    
    @IBAction func recenter(_ sender: UIButton) {
        cameraMoveToLocation(toLocation: currentLocation?.coordinate)
    }
    // END UI CODE
    
}


