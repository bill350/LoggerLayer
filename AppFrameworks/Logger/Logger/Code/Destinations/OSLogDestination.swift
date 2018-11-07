// Logger
// Copyright © 2018 Back Market. All rights reserved.

import Foundation
import os

final class OSLogDestination: LoggerDestination {
  
  override init(identification: Logger.Identification, level: Logger.Level = .verbose) {
    super.init(identification: identification, level: level)

    self.levelColor.verbose = "⚪️ "
    self.levelColor.debug = "☑️ "
    self.levelColor.info = "🔵 "
    self.levelColor.warning = "🔶 "
    self.levelColor.error = "🔴 "
    self.format = "$C$L $c $N.$F:$l - $M"
    
  }
  
  override func send(_ level: Logger.Level, msg: String, thread: String, file: String, function: String, line: Int, context: LogContext) -> String? {
    
    let formatedMsg = super.send(level, msg: msg, thread: thread, file: file, function: function, line: line)
    
    if let formatedMsg = formatedMsg {
      let log = self.createOSLog(context: context)
      
      os_log("%@",
             log: log,
             type: self.osLogLevelRelated(to: level),
             formatedMsg)
      return formatedMsg
    }
    
    return formatedMsg
  }
  
}

private extension OSLogDestination {
  
  func createOSLog(context: LogContext) -> OSLog {
    let category = context.rawValue
    let subsystem = self.moduleIdentification.bundleIdentifier
    let customLog = OSLog(subsystem: subsystem, category: category)
    return customLog
  }
  
  func osLogLevelRelated(to logLevel: Logger.Level) -> OSLogType {
    var logType: OSLogType
    switch logLevel {
    case .verbose:
      logType = .default
    case .debug:
      logType = .debug
    case .info:
      logType = .info
    case .warning:
      //We use "error" here because of 🔶 indicator in the Console
      logType = .error
    case .error:
      //We use "fault" here because of 🔴 indicator in the Console
      logType = .fault
    }
    
    return logType
  }
}
