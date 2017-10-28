//
//  BeerPlace.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/09.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import GooglePlaces

class Restaurant {
    var key: String = ""
    var name: String = ""
    var lat: Double = 0
    var lon: Double = 0
    var placeId: String = ""
    var distance: Int? = nil
    var travelTime: String? = nil
    var address: String? = nil
    var attributions: String? = nil
    var phoneNumber: String? = nil
    var website: String? = nil
    var openNowStatus: String? = nil
    var metadata: [GMSPlacePhotoMetadata]? = nil
    var isFavorite = false
    
    init(data: [String: Any]) {
        self.key = data["key"] as! String
        self.name = data["name"] as! String
        self.lat = data["lat"] as! Double
        self.lon = data["lon"] as! Double
        self.placeId = data["place_id"] as! String
        self.distance = data["distance"] as? Int
        self.travelTime = data["travel_time"] as? String
        self.address = data["address"] as? String
        self.attributions = data["attribution"] as? String
        self.phoneNumber = data["phone_number"] as? String
    }
}
