//
//  WidgetResponseRegistry.swift
//  Hyperswitch
//
//  Copyright © 2026 Hyperswitch. All rights reserved.
//

import Foundation

/**
 * WidgetResponseRegistry maintains a mapping of rootTag -> callback closure
 * for direct dispatch of widget payment results without using NotificationCenter.
 *
 * This replaces the NotificationCenter-based broadcast-and-filter pattern with
 * direct lookups, improving efficiency and simplifying lifecycle management.
 */
internal final class WidgetResponseRegistry {

    internal static let shared = WidgetResponseRegistry()

    /// Closure signature: (response: String, shouldRemoveView: Bool) -> Void
    private var handlers: [NSNumber: (String, Bool) -> Void] = [:]
    private let lock = NSLock()

    private init() {}

    /**
     * Register a handler closure for a given rootTag.
     * Only one handler can be registered per rootTag (last one wins).
     * Thread-safe: acquires internal lock.
     */
    internal func register(rootTag: NSNumber, handler: @escaping (String, Bool) -> Void) {
        lock.lock()
        handlers[rootTag] = handler
        lock.unlock()
    }

    /**
     * Unregister the handler for a given rootTag.
     * Should be called when the widget is deallocated.
     * Thread-safe: acquires internal lock.
     */
    internal func unregister(rootTag: NSNumber) {
        lock.lock()
        handlers.removeValue(forKey: rootTag)
        lock.unlock()
    }

    /**
     * Dispatch a response to the handler registered for rootTag.
     *
     * - Parameters:
     *   - rootTag: The React root tag identifying the target widget
     *   - response: The response payload as JSON string
     *   - shouldRemoveView: Whether this response triggers widget cleanup
     *
     * - Returns: true if a handler was found and called, false otherwise
     *
     * When shouldRemoveView is true, the handler is automatically unregistered
     * during dispatch to ensure proper cleanup.
     * Thread-safe: acquires internal lock.
     */
    @discardableResult
    internal func dispatch(rootTag: NSNumber, response: String, shouldRemoveView: Bool) -> Bool {
        lock.lock()
        let handler = handlers[rootTag]
        handlers.removeValue(forKey: rootTag)
        lock.unlock()
        handler?(response, shouldRemoveView)
        return handler != nil
    }
}
