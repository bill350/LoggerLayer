// Logger
// Copyright © 2018 Back Market. All rights reserved.

import Foundation
import NSLogger

final class NSLoggerDestination: LoggerDestination {
  
  private var nslogger = NSLogger.Logger.shared
  
  override func send(_ level: Logger.Level, msg: String, thread: String, file: String, function: String, line: Int, context: LogContext) -> String? {
    
    let domain = NSLogger.Logger.Domain.custom(context.rawValue)
    
    self.nslogger.log(domain, self.relatedLevel(for: level), msg, file, line, function)
    
    return super.send(level, msg: msg, thread: thread, file: file, function: function, line: line, context: context)
  }
}

private extension NSLoggerDestination {
  
  func relatedLevel(for logLevel: Logger.Level) -> NSLogger.Logger.Level {
    switch logLevel {
    case .debug:
      return NSLogger.Logger.Level.debug
    case .error:
      return NSLogger.Logger.Level.error
    case .info:
      return NSLogger.Logger.Level.info
    case .verbose:
      return NSLogger.Logger.Level.verbose
    case .warning:
      return NSLogger.Logger.Level.warning
    }
  }
}
