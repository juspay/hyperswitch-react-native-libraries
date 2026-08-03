//
//  StandardResult.swift
//  Hyperswitch
//
//  Standard result format for passing data between native and JS layers.
//  Matches Android's StandardResult exactly - works with raw JSON strings.
//
//  Created by OpenCode AI on 03/08/26.
//

import Foundation

/// Standard result format that works directly with JSON strings.
/// Avoids intermediate conversions and ensures all fields are preserved.
public struct StandardResult {
    public let rawJSON: String
    
    /// Initialize from raw JSON string (preserves all fields)
    public init(rawJSON: String) {
        self.rawJSON = rawJSON
    }
    
    /// Initialize from dictionary (for constructing results)
    public init(dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let json = String(data: data, encoding: .utf8) {
            self.rawJSON = json
        } else {
            self.rawJSON = "{\"status\":\"failed\",\"message\":\"Serialization error\"}"
        }
    }

    /// Single conversion point from the public `PaymentResult` (used by native widgets)
    /// to the React Native boundary format (`StandardResult`). Everything downstream of
    /// the public widgets should operate on this, never on `PaymentResult` directly.
    public init(paymentResult: PaymentResult) {
        switch paymentResult {
        case .completed(let data), .canceled(let data):
            // `data` is already the raw JSON string produced by the embedded bundle —
            // pass it through untouched (matches Android behavior).
            self = StandardResult(rawJSON: data)
        case .failed(let error as NSError):
            // Honor an original raw JSON payload from the embedded bundle if present.
            if let rawJSON = error.userInfo["rawJSON"] as? String {
                self = StandardResult(rawJSON: rawJSON)
            } else {
                self = StandardResult.failed(
                    code: error.domain.isEmpty ? nil : error.domain,
                    message: error.userInfo["message"] as? String ?? error.localizedDescription,
                    error: error
                )
            }
        }
    }
    
    /// Convenience initializers matching Android's StandardResult
    public static func success(code: String? = nil, message: String? = nil, data: Any? = nil) -> StandardResult {
        var dict: [String: Any] = ["status": "success"]
        if let code = code { dict["code"] = code }
        if let message = message { dict["message"] = message }
        if let data = data { dict["data"] = data }
        return StandardResult(dict: dict)
    }
    
    public static func failed(code: String? = nil, type: String? = nil, message: String? = nil, error: Error? = nil) -> StandardResult {
        var dict: [String: Any] = ["status": "failed"]
        dict["code"] = code ?? "UNKNOWN_ERROR"
        if let type = type { dict["type"] = type }
        dict["message"] = message ?? error?.localizedDescription ?? "An error has occurred."
        if let error = error {
            dict["error"] = error.localizedDescription
        }
        return StandardResult(dict: dict)
    }
    
    public static func cancelled(code: String? = nil, message: String? = "Payment cancelled", data: Any? = nil) -> StandardResult {
        var dict: [String: Any] = ["status": "cancelled"]
        if let code = code { dict["code"] = code }
        dict["message"] = message ?? "Payment cancelled"
        if let data = data { dict["data"] = data }
        return StandardResult(dict: dict)
    }
    
    /// Parse from raw JSON string and determine status
    public var status: String {
        guard let data = rawJSON.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = dict["status"] as? String else {
            return "failed"
        }
        return status
    }
    
    public var isSuccess: Bool {
        return ["success", "succeeded", "completed", "requires_capture"].contains(status)
    }
    
    public var isFailed: Bool {
        return ["failed", "requires_payment_method", "form_invalid"].contains(status)
    }
    
    public var isCancelled: Bool {
        return ["cancelled", "canceled"].contains(status)
    }
}
