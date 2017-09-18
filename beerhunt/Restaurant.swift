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
    var key = ""
    var name: String
    var lat: Double
    var lon: Double
    var placeId: String
    var distance: Int?
    var travelTime: String?
    var address: String?
    var attributions: String?
    var phoneNumber: String? {
        didSet {
            self.phoneNumber = self.phoneNumber?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+81", with: "0")
        }
    }
    var website: String?
    var openNowStatus: String?
    var metadata: [GMSPlacePhotoMetadata]?
    
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
