//
//  Post.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/06/17.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import GooglePlaces
import Firebase

class Post: Model {

    var photo = ""
    var body: String = ""
    var userId = ""
    var author = ""
    var restaurantKey = ""
    var createdAt: NSDate?
    var updatedAt: NSDate?

    init(key: String = "", photo: String, body: String = "", userId: String, author: String, restaurantKey: String) {
        super.init(snapshot: nil)
        self.ref = nil
        self.key = key
        self.photo = photo
        self.body = body
        self.userId = userId
        self.author = author
        self.restaurantKey = restaurantKey
        self.createdAt = nil
        self.updatedAt = nil
    }

    init?(snapshot: DataSnapshot) {
        guard
            let data = snapshot.value as? [String: Any],
            let photo = data["photo"] as? String,
            let body = data["body"] as? String,
            let userId = data["user_id"] as? String,
            let author = data["author"] as? String,
            let restaurantKey = data["restaurant_key"] as? String,
            let createdAt = data["created_at"] as? TimeInterval,
            let updatedAt = data["updated_at"] as? TimeInterval
        else {
                return nil
        }
        super.init(snapshot: snapshot)
        self.photo = photo
        self.body = body
        self.userId = userId
        self.author = author
        self.restaurantKey = restaurantKey
        self.createdAt = NSDate(timeIntervalSince1970: createdAt/1000)
        self.updatedAt = NSDate(timeIntervalSince1970: updatedAt/1000)
    }

    func toAnyObject() -> [String: Any] {
        return [
            "photo": self.photo,
            "body": self.body,
            "user_id": self.userId,
            "author": self.author,
            "restaurantKey": self.restaurantKey
        ]
    }

}
