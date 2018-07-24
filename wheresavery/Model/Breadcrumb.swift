//
//  Breadcrumb.swift
//  wheresavery
//
//  Created by Avery Ni on 7/23/18.
//  Copyright © 2018 Avery Ni. All rights reserved.
//

import Foundation

protocol SerializableDocument {
    init?(dictionary:[String:Any])
}

struct Breadcrumb {
    var latitude:Double
    var longitude:Double
    var timestamp:Date
    
    var dictionary:[String:Any] {
        return [
            "latitude": latitude,
            "longitude": longitude,
            "timestamp" : timestamp
        ]
    }
}

extension Breadcrumb : SerializableDocument {
    init?(dictionary: [String : Any]) {
        guard let latitude = dictionary["latitude"] as? Double,
            let longitude = dictionary["longitude"] as? Double,
            let timestamp = dictionary["timestamp"] as? Date else {return nil}
        
        self.init(
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp
        )
    }
}
