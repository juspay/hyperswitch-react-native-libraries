//
//  NativePaymentWidgetRegistry.swift
//  Hyperswitch
//
//  Instance-based registry for tracking widget views by React tag.
//  Uses weak references to prevent memory leaks.
//  Supports bidirectional lookup: outer view tag <-> embedded widget tag
//
//  Architecture:
//  Merchant App RN → NativePaymentWidgetView (reactTag)
//                      ↓
//                    Embedded RN Runtime → PaymentWidget (rootReactTag)
//
//  Created by Kuntimaddi Manideep on 02/08/26.
//

import Foundation
import React

/// Registry for tracking NativePaymentWidgetView instances by their React tag.
/// Uses weak references to avoid retain cycles and memory leaks.
/// Thread-safe with NSLock.
@objc(NativePaymentWidgetRegistry)
public final class NativePaymentWidgetRegistry: NSObject {
    
    /// Weak wrapper to store views without retaining them
    private class WeakViewWrapper {
        weak var view: NativePaymentWidgetView?
        init(_ view: NativePaymentWidgetView) {
            self.view = view
        }
    }
    
    /// Shared instance accessed by both view manager and helper modules
    @objc public static let shared = NativePaymentWidgetRegistry()
    
    // Primary registry: outer view's reactTag → view
    private var viewsByOuterTag: [NSNumber: WeakViewWrapper] = [:]
    
    // Reverse lookup: embedded widget's rootReactTag → outer view's reactTag
    private var outerTagByEmbeddedTag: [NSNumber: NSNumber] = [:]
    
    private let lock = NSLock()
    
    private override init() {
        super.init()
    }
    
    /// Register a view with its React tag. Automatically uses weak reference.
    /// If the view has an embedded widget (rctRootTag), also registers the reverse mapping.
    @objc public func register(view: NativePaymentWidgetView, tag: NSNumber) {
        lock.lock()
        defer { lock.unlock() }
        
        viewsByOuterTag[tag] = WeakViewWrapper(view)
        
        // If view has embedded widget tag, create reverse mapping
        if let embeddedTag = view.rctRootTag {
            outerTagByEmbeddedTag[embeddedTag] = tag
        }
    }
    
    /// Update the embedded tag mapping when widget is created after initial registration
    @objc public func updateEmbeddedTag(_ embeddedTag: NSNumber, forOuterTag outerTag: NSNumber) {
        lock.lock()
        defer { lock.unlock() }
        outerTagByEmbeddedTag[embeddedTag] = outerTag
    }
    
    /// Unregister a view by its React tag.
    @objc public func unregister(tag: NSNumber) {
        lock.lock()
        defer { lock.unlock() }
        
        // Remove reverse mapping if exists
        if let view = viewsByOuterTag[tag]?.view,
           let embeddedTag = view.rctRootTag {
            outerTagByEmbeddedTag.removeValue(forKey: embeddedTag)
        }
        
        viewsByOuterTag.removeValue(forKey: tag)
    }
    
    /// Retrieve a view by its outer React tag. Returns nil if view was deallocated.
    @objc public func view(forTag tag: NSNumber) -> NativePaymentWidgetView? {
        lock.lock()
        defer { lock.unlock() }
        
        // Clean up deallocated views
        if let wrapper = viewsByOuterTag[tag], wrapper.view == nil {
            viewsByOuterTag.removeValue(forKey: tag)
            return nil
        }
        
        return viewsByOuterTag[tag]?.view
    }
    
    /// Retrieve a view by its embedded widget's rootReactTag.
    /// This is the key method for HyperModule callbacks that receive the embedded tag.
    @objc public func view(forEmbeddedTag embeddedTag: NSNumber) -> NativePaymentWidgetView? {
        lock.lock()
        defer { lock.unlock() }
        
        // Find outer tag from embedded tag
        guard let outerTag = outerTagByEmbeddedTag[embeddedTag] else {
            return nil
        }
        
        // Clean up deallocated views
        if let wrapper = viewsByOuterTag[outerTag], wrapper.view == nil {
            viewsByOuterTag.removeValue(forKey: outerTag)
            outerTagByEmbeddedTag.removeValue(forKey: embeddedTag)
            return nil
        }
        
        return viewsByOuterTag[outerTag]?.view
    }
    
    /// Clean up all nil (deallocated) entries. Called automatically but can be invoked manually.
    @objc public func cleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        // Remove deallocated views and their embedded tag mappings
        let deadTags = viewsByOuterTag.filter { $0.value.view == nil }.map { $0.key }
        for tag in deadTags {
            if let wrapper = viewsByOuterTag[tag],
               let embeddedTag = wrapper.view?.rctRootTag {
                outerTagByEmbeddedTag.removeValue(forKey: embeddedTag)
            }
            viewsByOuterTag.removeValue(forKey: tag)
        }
    }
}
