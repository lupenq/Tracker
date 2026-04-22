//
//  TrackerCategory.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import Foundation

struct TrackerCategory: Hashable, Sendable {
    let title: String
    let trackers: [Tracker]
}
