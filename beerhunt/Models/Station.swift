//
//  Station.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/11.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Station: Model {
    var name: String!
    var prefecture: String!
    var city: String!
    var furigana: String!
    var line: String!

    init?(snapshot: DataSnapshot) {
        guard
            let data = snapshot.value as? [String: Any],
            let name = data["name"] as? String,
            let furigana = data["furigana"] as? String,
            let prefecture = data["prefecture"] as? String,
            let city = data["city"] as? String,
            let line = data["line"] as? String
        else {
            return nil
        }
        super.init(snapshot: snapshot)
        self.name = name
        self.furigana = furigana
        self.prefecture = prefecture
        self.city = city
        self.line = line
    }
}
