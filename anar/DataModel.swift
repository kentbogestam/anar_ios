//
//  DataModel.swift
//  Anar Find&Eat
//
//  Created by Ashish Pal on 20/07/20.
//  Copyright © 2020 Dastjar Ab. All rights reserved.
//

import Foundation


struct DataModel {
    var lat = "0.00", long = "0.00", action = "", locationPermission = "1"
    
    private var dictionary: [String: Any] {
        return [
            "lat": lat,
            "long": long,
            "action": action,
            "locationPermission": locationPermission
        ]
    }
    
    var nsDictionary: NSDictionary {
        return dictionary as NSDictionary
    }
}
