//
//  Item.swift
//  ShiritoriApp
//  
//  Created on 2025/07/11
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
