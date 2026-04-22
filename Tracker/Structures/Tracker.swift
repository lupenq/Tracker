//
//  Tracker.swift
//  Tracker
//
//  Created by Ilia Degtiarev on 13/04/2026.
//

import Foundation

enum TrackerSchedule: Hashable, Sendable {
    case habit(weekdays: Set<Int>)
    case irregularEvent
}

struct Tracker: Hashable, Sendable {
    let id: UUID
    let name: String
    let colorAssetName: String
    let emoji: String
    let schedule: TrackerSchedule
}
