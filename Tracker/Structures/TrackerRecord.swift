//
//  TrackerRecord.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import Foundation

struct TrackerRecord: Hashable, Sendable {
    let trackerId: UUID
    let date: Date
}
