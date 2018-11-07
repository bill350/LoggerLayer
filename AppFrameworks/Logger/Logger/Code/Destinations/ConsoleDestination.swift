// Logger
// Copyright © 2018 Back Market. All rights reserved.

import Foundation

final class ConsoleDestination: LoggerDestination {
  
  override init(identification: Logger.Identification, level: Logger.Level = .verbose) {
    super.init(identification: identification, level: level)

    self.levelColor.verbose = "⚪️ "
    self.levelColor.debug = "☑️ "
    self.levelColor.info = "🔵 "
    self.levelColor.warning = "🔶 "
    self.levelColor.error = "🔴 "
  }
  
  // print to Xcode Console. uses full base class functionality
  override func send(_ level: Logger.Level, msg: String, thread: String, file: String, function: String, line: Int, context: LogContext) -> String? {
    
    let formattedString = super.send(level, msg: msg, thread: thread, file: file, function: function, line: line, context: context)
    
    if let str = formattedString {
      print(str)
    }
    return formattedString
    
  }
}
