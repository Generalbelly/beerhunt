//
//  Model.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/19.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Model {
    var key: String?
    var ref: DatabaseReference?

    init(snapshot: DataSnapshot?) {
        if let snapshot = snapshot {
            self.key = snapshot.key
            self.ref = snapshot.ref
        }
    }

    func updateChilValues(values: [String: Any]) {
        guard let ref = self.ref else { return }
        var data = values
        data["updated_at"] = ServerValue.timestamp()
        ref.updateChildValues(data)
    }
}
