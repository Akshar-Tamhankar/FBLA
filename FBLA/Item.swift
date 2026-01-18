//
//  Item.swift
//  FBLA
//
//  Created by Akshar Tamhankar on 1/6/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
