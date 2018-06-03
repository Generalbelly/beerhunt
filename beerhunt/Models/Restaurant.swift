//
//  BeerPlace.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/09.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import GooglePlaces
import FirebaseDatabase

class Restaurant: Model {
    var name: String! {
        didSet {
            if self.name != "" {
                self.updateChilValues(values: ["name": self.name])
            }
        }
    }
    var lat: Double = 0
    var lon: Double = 0
    var placeId: String?
    var distance: Int?
    var travelTime: String?
    var createdAt: NSDate?
    var updatedAt: NSDate?

    var address: String?
    var attributions: String?
    var phoneNumber: String?
    var website: String?
    var metadata: [GMSPlacePhotoMetadata]?
    var isFavorite = false

    init?(snapshot: DataSnapshot) {
        guard
            let data = snapshot.value as? [String: Any],
            let name = data["name"] as? String,
            let lat = data["lat"] as? Double,
            let lon = data["lon"] as? Double,
            let createdAt = data["created_at"] as? TimeInterval,
            let updatedAt = data["updated_at"] as? TimeInterval
        else {
                return nil
        }
        super.init(snapshot: snapshot)
        self.name = name
        self.lat = lat
        self.lon = lon
        self.createdAt = NSDate(timeIntervalSince1970: createdAt/1000)
        self.updatedAt = NSDate(timeIntervalSince1970: updatedAt/1000)
        self.distance = data["distance"] as? Int
        self.travelTime = data["travel_time"] as? String
        self.address = data["address"] as? String
        self.attributions = data["attributions"] as? String
        self.phoneNumber = data["phone_number"] as? String
        self.placeId = data["place_id"] as? String
    }
}
