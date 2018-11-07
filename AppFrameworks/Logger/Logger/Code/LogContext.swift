// Logger
// Copyright © 2018 Back Market. All rights reserved.

import Foundation

public struct LogContext: RawRepresentable {
  public var isEnabled = true
  public let rawValue: String
  
  public init(rawValue: String) { self.rawValue = rawValue }
  
  public static let app = LogContext(rawValue: "📱 App")
  public static let layout = LogContext(rawValue: "🔲 View Layout")
  public static let routing = LogContext(rawValue: "⛵️ Routing")
  public static let service = LogContext(rawValue: "🌍 Service")
  public static let model = LogContext(rawValue: "🏛 Model")
  public static let memory = LogContext(rawValue: "✅ Memory deinit")
  
  public static func custom(_ value: String, enabled: Bool = true) -> LogContext {
    var context = LogContext(rawValue: value)
    context.isEnabled = enabled
    return context
  }
}
