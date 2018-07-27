//
//  ReachabilityManager.swift
//  wheresavery
//
//  Created by Avery Ni on 7/27/18.
//  Copyright © 2018 Avery Ni. All rights reserved.
//

import UIKit
import ReachabilitySwift

class ReachabilityManager: NSObject {
    static let shared = ReachabilityManager()
    public var breadcrumbManager: BreadcrumbManager?
    
    var isNetworkAvailable : Bool {
        return reachabilityStatus != .notReachable
    }
    
    var reachabilityStatus: Reachability.NetworkStatus = .notReachable
    
    let reachability = Reachability()!
    
    @objc func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability
        reachabilityStatus = reachability.currentReachabilityStatus
        switch reachabilityStatus {
        case .notReachable:
            print("Network unreachable")
        case .reachableViaWiFi:
            if breadcrumbManager != nil {
                breadcrumbManager?.uploadBreadcrumbs()
            }
        case .reachableViaWWAN:
            print("Network reached through Cellular Data")
        }
    }
    
    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reachabilityChanged),
                                               name: ReachabilityChangedNotification,
                                               object: reachability)
        do{
            try reachability.startNotifier()
        } catch {
            print("Failed to start reachability manager")
        }
    }
    
    func stopMonitoring(){
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self,
                                                  name: ReachabilityChangedNotification,
                                                  object: reachability)
    }
}
