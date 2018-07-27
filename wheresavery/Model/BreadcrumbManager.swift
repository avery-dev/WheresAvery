//
//  BreadcrumbManager.swift
//  wheresavery
//
//  Created by Avery Ni on 7/25/18.
//  Copyright © 2018 Avery Ni. All rights reserved.
//

import Foundation
import Firebase

class BreadcrumbManager {
    private var db: Firestore!
    private var breadcrumbTrail: [String:[String:Breadcrumb]]
    private var dateFormatter: DateFormatter?
    private var timeFormatter: DateFormatter?
    private var breadcrumbsToBeUploaded = [Breadcrumb]()
    
    init() {
        db = Firestore.firestore()
        breadcrumbTrail = [String:[String:Breadcrumb]]()
        
        // Date-Time Formatter initialization
        dateFormatter = DateFormatter()
        dateFormatter?.dateFormat = CONSTANTS.TIME.DateFormat
        timeFormatter = DateFormatter()
        timeFormatter?.dateFormat = CONSTANTS.TIME.HourFormat
        timeFormatter?.timeZone = TimeZone.current
    }
    
    func retrieveBreadcrumbsFromDate(date: Date, completion: @escaping () -> Void) {
        let dateId = dateFormatter?.string(from: date)
        let start = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
        let end = start.addingTimeInterval(86400)
        
        // If data is already cached/retrieved
        if breadcrumbTrail[dateId!] != nil {
            //Do nothing and finish (use cached values)
            completion()
        }
        // Else pull data
        else {
            db.collection(CONSTANTS.DATA.User)
            .whereField(CONSTANTS.DATA.Timestamp, isGreaterThan: start)
            .whereField(CONSTANTS.DATA.Timestamp, isLessThan: end)
            .getDocuments() {
                querySnapshot, error in
                if let error = error {
                    print("\(error.localizedDescription )")
                    completion()
                } else {
                    self.breadcrumbTrail[dateId!] = [String:Breadcrumb]()
                    for document in (querySnapshot?.documents)! {
                        let breadcrumb = Breadcrumb(dictionary: document.data())
                        let timeId = (self.timeFormatter?.string(from: (breadcrumb?.timestamp)!))!
                        self.breadcrumbTrail[dateId!]![timeId] = breadcrumb
                    }
                    completion()
                }
            }
         }
    }
    
    func getBreadcrumbsFromDateId(dateId: String)->[String:Breadcrumb] {
        return self.breadcrumbTrail[dateId]!
    }
    
    func addBreadcrumb(breadcrumb: Breadcrumb) {
        let dateId = (dateFormatter?.string(from: breadcrumb.timestamp))!
        let timeId = (timeFormatter?.string(from: breadcrumb.timestamp))!
        breadcrumbTrail[dateId]![timeId] = breadcrumb
        breadcrumbsToBeUploaded.append(breadcrumb)
        if ReachabilityManager.shared.reachability.currentReachabilityStatus == .reachableViaWiFi {
            uploadBreadcrumbs()
        }
    }
    
    func uploadBreadcrumbs() {
        for breadcrumb in breadcrumbsToBeUploaded {
            db.collection(CONSTANTS.DATA.User).document(breadcrumb.timestamp.description)
                .setData(breadcrumb.dictionary) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Successfully uploaded breadcrumb at ", breadcrumb.timestamp.description)
                    }
            }
        }
        breadcrumbsToBeUploaded.removeAll()
    }
    
    
    
}
