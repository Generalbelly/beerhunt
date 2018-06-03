//
//  SearchItemModel.swift
//  beerhunt
//
//  Created by ShimmenNobuyoshi on 2018/05/21.
//  Copyright © 2018年 ShimmenNobuyoshi. All rights reserved.
//

import Foundation

struct SearchItemModel {
    let id: String
    let title: String
    init(_ id: String, _ title: String) {
        self.id = id
        self.title = title
    }
}

extension SearchItemModel: SearchItem {
    func matchesSearchQuery(_ query: String) -> Bool {
        return title.contains(query)
    }
}

extension SearchItemModel: Equatable {
    static func == (lhs: SearchItemModel, rhs: SearchItemModel) -> Bool {
        return lhs.id == rhs.id
    }
}

extension SearchItemModel: CustomStringConvertible {
    var description: String {
        return title
    }
}
