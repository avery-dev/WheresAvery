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
    
    init() {
        db = Firestore.firestore()
        breadcrumbTrail = [String:[String:Breadcrumb]]()
    }
    
    func retrieveBreadcrumbsFromDate(date: Date, dateId: String, completion: @escaping () -> Void) {
        let start = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
        let end = start.addingTimeInterval(86400)
        
        // Add cache checks
        // - current day case
        // - already pulled case
        // NOTE - Do I need to add completion?
        
        db.collection(CONSTANTS.DATA.User)
            .whereField(CONSTANTS.DATA.Timestamp, isGreaterThan: start)
            .whereField(CONSTANTS.DATA.Timestamp, isLessThan: end)
            .getDocuments() {
                querySnapshot, error in
                if let error = error {
                    print("\(error.localizedDescription )")
                    completion()
                } else {
                    var breadcrumbsDayTrail = [String:Breadcrumb]()
                    for document in (querySnapshot?.documents)! {
                        breadcrumbsDayTrail[document.documentID] = Breadcrumb(dictionary: document.data())
                    }
                    self.breadcrumbTrail[dateId] = breadcrumbsDayTrail
                    completion()
                }
        }
    }
    
    func getBreadcrumbsFromDateId(dateId: String)->[String:Breadcrumb] {
        return self.breadcrumbTrail[dateId]!
    }
    
    func uploadBreadcrumb(breadcrumb: Breadcrumb) {
        db.collection(CONSTANTS.DATA.User).document(breadcrumb.timestamp.description)
            .setData(breadcrumb.dictionary) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document successfully written")
            }
        }
        
    }
    
    
    
}
