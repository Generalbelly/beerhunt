//
//  SearchableItem.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/16.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import SearchTextField

enum SearhableItemData {
    case station(Station)
    case restaurant(Restaurant)
    case userLocation(String)
}

class SearhableItem: SearchTextFieldItem {
    public var station: Station?
    public var restaurant: Restaurant?
    public var isUserLocation = false

    public init(data: SearhableItemData) {
        switch data {
        case .station(let station):
            super.init(title: station.name)
            self.title = station.name
            self.station = station
        case .restaurant(let restaurant):
            super.init(title: restaurant.name)
            self.title = restaurant.name
            self.restaurant = restaurant
        case .userLocation(let title):
            super.init(title: title)
            self.title = title
            self.isUserLocation = true
        }
    }

}
