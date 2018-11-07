// Logger
// Copyright © 2018 Back Market. All rights reserved.
// Courtesy of SwiftyBeaver MIT Licence
// Mainly inspired from SwiftyBeaver destination principle
// https://github.com/SwiftyBeaver/SwiftyBeaver

import Foundation

// swiftlint:disable vertical_parameter_alignment
// swiftlint:disable function_parameter_count

/// Create your own logger for each module of the app
public final class Logger {
  
  public enum Level: Int {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
  }
  
  public struct Identification {
    let identifier: String
    let bundleIdentifier: String
  }
  
  private let identification: Identification

  // Destinations 🔌
  public private(set) var destinations = Set<LoggerDestination>()
  
  private(set) lazy var basicDestination = ConsoleDestination(identification: self.identification)
  private(set) lazy var nsloggerDestination = NSLoggerDestination(identification: self.identification)
  private(set) lazy var osLogDestination = OSLogDestination(identification: self.identification)
  
  // MARK: Initializer
  public init(identifier: String, bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
    let bundleID = bundleIdentifier ?? ""
    self.identification = Identification(identifier: identifier,
                                         bundleIdentifier: bundleID)
  }
  
  // MARK: 🔌 Destinations set up 🔌
  public func setBasicConsole(enabled isEnabled: Bool, level: Logger.Level = .verbose) {
    self.basicDestination.minLevel = level
    if isEnabled {
      self.addDestination(self.basicDestination)
    } else {
      self.removeDestination(self.basicDestination)
    }
  }
  
  public func setOSLog(enabled: Bool, level: Logger.Level = .verbose) {
    self.osLogDestination.minLevel = level
    if enabled {
      self.addDestination(self.osLogDestination)
    } else {
      self.removeDestination(self.osLogDestination)
    }
  }
  
  public func setNSLogger(enabled isEnabled: Bool, level: Logger.Level = .verbose) {
    self.nsloggerDestination.minLevel = level
    if isEnabled {
      self.addDestination(self.nsloggerDestination)
    } else {
      self.removeDestination(self.nsloggerDestination)
    }
  }
  
  // MARK: 🚥 Logging methods 🚥
  
  /// log something generally unimportant (lowest priority)
  public func verbose(_ message: @autoclosure () -> Any,
                      _ file: String = #file,
                      _ function: String = #function,
                      line: Int = #line,
                      context: LogContext) {
    self.custom(level: .verbose, message: message, file: file, function: function, line: line, context: context)
  }
  
  /// log something which help during debugging (low priority)
  public func debug(_ message: @autoclosure () -> Any, _
    file: String = #file, _ function: String = #function, line: Int = #line, context: LogContext) {
    self.custom(level: .debug, message: message, file: file, function: function, line: line, context: context)
  }
  
  /// log something which you are really interested but which is not an issue or error (normal priority)
  public func info(_ message: @autoclosure () -> Any, _
    file: String = #file, _ function: String = #function, line: Int = #line, context: LogContext) {
    self.custom(level: .info, message: message, file: file, function: function, line: line, context: context)
  }
  
  /// log something which may cause big trouble soon (high priority)
  public func warning(_ message: @autoclosure () -> Any, _
    file: String = #file, _ function: String = #function, line: Int = #line, context: LogContext) {
    self.custom(level: .warning, message: message, file: file, function: function, line: line, context: context)
  }
  
  /// log something which will keep you awake at night (highest priority)
  public func error(_ message: @autoclosure () -> Any, _
    file: String = #file, _ function: String = #function, line: Int = #line, context: LogContext) {
    self.custom(level: .error, message: message, file: file, function: function, line: line, context: context)
  }
  
  /// custom logging to manually adjust values, should just be used by other frameworks
  public func custom(level: Logger.Level,
                     message: @autoclosure () -> Any,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line,
                     context: LogContext) {
    guard context.isEnabled else { return }
    dispatch_send(level: level, message: message, thread: threadName(),
                  file: file, function: function, line: line, context: context)
  }
}

// MARK: 🔌 Destination Handling 🔌
private extension Logger {
  
  /// returns boolean about success
  @discardableResult
  func addDestination(_ destination: LoggerDestination) -> Bool {
    if destinations.contains(destination) {
      return false
    }
    destinations.insert(destination)
    return true
  }
  
  /// returns boolean about success
  @discardableResult
  func removeDestination(_ destination: LoggerDestination) -> Bool {
    if destinations.contains(destination) == false {
      return false
    }
    destinations.remove(destination)
    return true
  }
  
  /// if you need to start fresh
  func removeAllDestinations() {
    destinations.removeAll()
  }
  
  /// returns the amount of destinations
  func countDestinations() -> Int {
    return destinations.count
  }
}

// MARK: Logger dispatching
private extension Logger {
  /// returns the current thread name
  func threadName() -> String {
    
    #if os(Linux)
    // on 9/30/2016 not yet implemented in server-side Swift:
    // > import Foundation
    // > Thread.isMainThread
    return ""
    #else
    if Thread.isMainThread {
      return ""
    } else {
      let threadName = Thread.current.name
      if let threadName = threadName, !threadName.isEmpty {
        return threadName
      } else {
        return String(format: "%p", Thread.current)
      }
    }
    #endif
  }
  
  /// internal helper which dispatches send to dedicated queue if minLevel is ok
  func dispatch_send(level: Logger.Level, message: @autoclosure () -> Any,
                     thread: String, file: String, function: String, line: Int, context: LogContext = LogContext.app) {
    var resolvedMessage: String?
    for dest in destinations {
      
      guard let queue = dest.queue else {
        continue
      }
      
      resolvedMessage = "\(message())"
      if dest.shouldLevelBeLogged(level, path: file, function: function, message: resolvedMessage) {
        // try to convert msg object to String and put it on queue
        if let msgStr = resolvedMessage {
          let strippedFunction = stripParams(function: function)
          
          if dest.asynchronously {
            queue.async {
              _ = dest.send(level, msg: msgStr, thread: thread, file: file, function: strippedFunction, line: line, context: context)
            }
          } else {
            queue.sync {
              _ = dest.send(level, msg: msgStr, thread: thread, file: file, function: strippedFunction, line: line, context: context)
            }
          }
        }
      }
    }
  }
  
  /// removes the parameters from a function because it looks weird with a single param
  func stripParams(function: String) -> String {
    var strippedFunction = function
    if let indexOfBrace = strippedFunction.index(of: "(") {
      strippedFunction = String(strippedFunction[..<indexOfBrace])
    }
    strippedFunction += "()"
    return strippedFunction
  }
}
// swiftlint:enable vertical_parameter_alignment
// swiftlint:enable function_parameter_count
