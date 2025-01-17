//
//  Item.swift
//  Lost
//
//  Created by franck.wan on 2025/1/17.
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
