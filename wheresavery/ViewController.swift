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
    private var initialRecenterDone = false
    private var currentLocation: CLLocation?
    private var lastUpdateTime: Date? // Last UI Map Upload Time
    private var dateFormatter = DateFormatter()
    private var timeFormatter = DateFormatter()
    private var datePicker: UIDatePicker?
    private var breadcrumbManager: BreadcrumbManager?
    private var breadcrumbKeys: [String]?
    private var currentMarkers: [String:GMSMarker]?
    
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
        self.timeSlider.isEnabled = false
        breadcrumbManager = BreadcrumbManager()
        breadcrumbManager?.retrieveBreadcrumbsFromDate(date: Date()) {
            self.locationManager.distanceFilter = CONSTANTS.DISTANCE.MinimumDistanceFilter
            self.locationManager.startUpdatingLocation()
            self.updateMapUIWithDate(date: Date(), focusOnMarker: false)
        }
        
        // Date-Time Formatter initialization
        dateFormatter.dateFormat = CONSTANTS.TIME.DateFormat
        timeFormatter.dateFormat = CONSTANTS.TIME.HourFormat
        
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
        
        // Markers
        currentMarkers = [String:GMSMarker]()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLoc = locations.last else { return }
        currentLocation = currentLoc
        
        // Initial Recenter
        if !initialRecenterDone {
            cameraMoveToLocation(toLocation: currentLocation?.coordinate)
            initialRecenterDone = true
        }
        
        // Upload data
        uploadLocation(location: currentLoc)
        regenerateSlider(dateId: (dateFormatter.string(from: currentLoc.timestamp)))
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
        ])!) {
            // If it is today, update the map
            if Calendar.current.isDateInToday(Date()) {
                let dateId = (self.dateFormatter.string(from: location.timestamp))
                let timeId = (self.timeFormatter.string(from: location.timestamp))
                self.addMarker(markerPosition: location.coordinate, title: timeId)
                self.regenerateSlider(dateId: dateId)
            }
        }
    }
    
    func addMarker(markerPosition: CLLocationCoordinate2D, title: String) {
        let marker = GMSMarker(position: markerPosition)
        marker.title = title
        marker.map = self.mapView
        self.currentMarkers![title] = marker
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
        datePicker?.minimumDate = dateFormatter.date(from: CONSTANTS.TIME.DateSelectionStartDate)
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
        dateField.text = dateFormatter.string(from: Date())
        
        view.bringSubview(toFront: timeContainer)
    }
    
    func regenerateSlider(dateId: String) {
        breadcrumbKeys = breadcrumbManager?.getBreadcrumbsFromDateId(dateId: dateId).keys.sorted()

        if (breadcrumbKeys?.count)! < 2 {
            if (breadcrumbKeys?.isEmpty)! {
                let alert = UIAlertController(title: "Oops!", message: "There are no breadcrumbs for this day", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            timeSlider.isEnabled = false
            return
        }
        timeSlider.isEnabled = true
        timeSlider.maximumValue = Float((breadcrumbKeys?.count)! - 1)
    }
    
    func initializeSliderValueAndMoveCamera(breadcrumbKeyIndex: Int = 0) {
        timeSlider.value = Float(breadcrumbKeyIndex)
        cameraMoveToLocation(toLocation: currentMarkers?[breadcrumbKeys![breadcrumbKeyIndex]]?.position, animate: false)
        self.mapView.selectedMarker = currentMarkers?[breadcrumbKeys![breadcrumbKeyIndex]]
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        // Get marker and move camera
        timeSlider.value = roundf(sender.value)
        let breadcrumbKeysIndex = Int(timeSlider.value)
        let markerKey = breadcrumbKeys![breadcrumbKeysIndex]
        let currentMarker = currentMarkers?[markerKey]
        self.mapView.selectedMarker = currentMarker
        cameraMoveToLocation(toLocation: currentMarker?.position, animate: false)
        
    }
    
    @objc func datePicked() {
        let dateId = dateFormatter.string(from: datePicker!.date)
        dateField.text = dateId
        updateMapUIWithDate(date: datePicker!.date)
        view.endEditing(true)
    }
    
    func updateMapUIWithDate(date: Date, focusOnMarker: Bool = true) {
        let dateId = dateFormatter.string(from: date)
        breadcrumbManager?.retrieveBreadcrumbsFromDate(date: date) {
            let breadcrumbs = self.breadcrumbManager?.getBreadcrumbsFromDateId(dateId: dateId)
            if (breadcrumbs == nil) {
                // This should never happen unless internet shits out?
            } else {
                self.mapView.clear()
                self.currentMarkers?.removeAll()
                // Drop a pin everywhere I was
                for data in (breadcrumbs)! {
                    let breadcrumb = data.value
                    let position = CLLocationCoordinate2D(latitude: breadcrumb.latitude, longitude: breadcrumb.longitude)
                    
                    self.addMarker(markerPosition: position, title: data.key)
                }
                self.regenerateSlider(dateId: dateId)
                if focusOnMarker {
                    self.initializeSliderValueAndMoveCamera()
                }
            }
        }
    }
    
    @objc func dateCancelled() {
        view.endEditing(true)
    }
    
    @IBAction func recenter(_ sender: UIButton) {
        cameraMoveToLocation(toLocation: currentLocation?.coordinate)
    }
    // END UI CODE
    
}


