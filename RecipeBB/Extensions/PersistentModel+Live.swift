//
//  PersistentModel+Live.swift
//  RecipeBB
//

import Foundation
import SwiftData

extension PersistentModel {
    /// Whether this object is still safe to read attributes from.
    ///
    /// A deleted object can outlive the delete: `@Query` results, cached
    /// arrays and in-flight view updates all keep strong references, and
    /// `@Query` doesn't reliably drop the object in the same runloop turn as
    /// `context.delete`. Reading an attribute at that point faults backing
    /// data that no longer exists and traps, so anything holding a model
    /// across a possible delete checks this before touching it.
    var isLive: Bool {
        !isDeleted && modelContext != nil
    }
}
