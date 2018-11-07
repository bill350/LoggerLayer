// PaymentKit
// Copyright © 2018 Back Market. All rights reserved.

import Foundation
import Logger

public struct PaymentModule {
  
  static let logger = Logger(identifier: "💸", bundleIdentifier: "com.bunny.payment")
  
  public static func configure() {
    self.setLogging(enabled: true)
  }
  
  static func setLogging(enabled: Bool) {
    if enabled {
      #if DEBUG
      logger.setBasicConsole(enabled: true)
      logger.setOSLog(enabled: false)
      logger.setNSLogger(enabled: true)
      #else
      logger.setBasicConsole(enabled: false, level: .error)
      logger.setOSLog(enabled: true, level: .error)
      logger.setNSLogger(enabled: true, level: .error)
      #endif
    }
  }
  
  struct Log {
    static let defaultContext = LogContext.custom("Payment 💸")
    static let paypalContext = LogContext.custom("Paypal 💰")
    static let creditCardContext = LogContext.custom("CB 💳")
  }
  
}
