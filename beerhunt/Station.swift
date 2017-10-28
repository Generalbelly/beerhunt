//
//  Station.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2017/09/11.
//  Copyright © 2017年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation

struct Station {
    var key: String = ""
    var name: String = ""
    var city: String = ""
    var furigana: String = ""
    var line: String = ""
    
    init(data: [String: String]) {
        self.key = data["key"]!
        self.name = data["name"]!
        self.furigana = data["furigana"]!
        self.city = data["city"]!
        self.line = data["line"]!
    }
}
