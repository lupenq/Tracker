//
//  TrackerPersistenceError.swift
//  Tracker
//

import Foundation

enum TrackerPersistenceError: Error {
    case trackerNotFound(id: UUID)
    case categoryNotFound(title: String)
}
