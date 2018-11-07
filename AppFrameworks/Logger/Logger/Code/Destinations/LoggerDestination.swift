// Logger
// Copyright © 2018 Back Market. All rights reserved.
// Courtesy of SwiftyBeaver MIT Licence
// Mainly inspired from SwiftyBeaver destination principle
// https://github.com/SwiftyBeaver/SwiftyBeaver

import Foundation

/// destination which all others inherit from. do not directly use
open class LoggerDestination: Hashable, Equatable {
  
  /// output format pattern, see documentation for syntax
  open var format = "$DHH:mm:ss.SSS$d $C$L [$i-$X]$c $N.$F:$l - $M"
  
  /// runs in own serial background thread for better performance
  open var asynchronously = true
  
  /// do not log any message which has a lower level than this one
  open var minLevel = Logger.Level.verbose
  
  /// set custom log level words for each level
  open var levelString = LevelString()
  
  /// set custom log level colors for each level
  open var levelColor = LevelColor()
  
  public struct LevelString {
    public var verbose = "VERBOSE"
    public var debug = "DEBUG"
    public var info = "INFO"
    public var warning = "WARNING"
    public var error = "ERROR"
  }
  
  // For a colored log level word in a logged line
  // empty on default
  public struct LevelColor {
    public var verbose = ""     // silver
    public var debug = ""       // green
    public var info = ""        // blue
    public var warning = ""     // yellow
    public var error = ""       // red
  }
  
  var reset = ""
  var escape = ""
  
  let formatter = DateFormatter()
  let startDate = Date()
  let moduleIdentification: Logger.Identification
  
  // each destination class must have an own hashValue Int
  lazy public var hashValue: Int = self.defaultHashValue
  open var defaultHashValue: Int {return 0}
  
  // each destination instance must have an own serial queue to ensure serial output
  // GCD gives it a prioritization between User Initiated and Utility
  var queue: DispatchQueue? //dispatch_queue_t?
  var debugPrint = false // set to true to debug the internal filter logic of the class
  
  public init(identification: Logger.Identification, level: Logger.Level = .verbose) {
    self.moduleIdentification = identification
    self.minLevel = level
    let uuid = NSUUID().uuidString
    let queueLabel = "Logger-queue-" + uuid
    queue = DispatchQueue(label: queueLabel, target: queue)
  }
  
  /// send / store the formatted log message to the destination
  /// returns the formatted log message for processing by inheriting method
  /// and for unit tests (nil if error)
  //swiftlint:disable function_parameter_count
  open func send(_ level: Logger.Level, msg: String, thread: String, file: String,
                 function: String, line: Int, context: LogContext = LogContext.app) -> String? {
      return formatMessage(format, level: level, msg: msg, thread: thread,
                           file: file, function: function, line: line, context: context)
  }
  
  public func execute(synchronously: Bool, block: @escaping () -> Void) {
    guard let queue = queue else {
      fatalError("Queue not set")
    }
    if synchronously {
      queue.sync(execute: block)
    } else {
      queue.async(execute: block)
    }
  }
  //swiftlint:enable function_parameter_count
  
  public func executeSynchronously<T>(block: @escaping () throws -> T) rethrows -> T {
    guard let queue = queue else {
      fatalError("Queue not set")
    }
    return try queue.sync(execute: block)
  }
  
  ////////////////////////////////
  // MARK: Format
  ////////////////////////////////
  
  /// returns (padding length value, offset in string after padding info)
  private func parsePadding(_ text: String) -> (Int, Int)
  {
    // look for digits followed by a alpha character
    var string: String!
    var sign: Int = 1
    if text.first == "-" {
      sign = -1
      string = String(text.suffix(from: text.index(text.startIndex, offsetBy: 1)))
    } else {
      string = text
    }
    let numStr = string.prefix { $0 >= "0" && $0 <= "9" }
    if let num = Int(String(numStr)) {
      return (sign * num, (sign == -1 ? 1 : 0) + numStr.count)
    } else {
      return (0, 0)
    }
  }
  
  private func paddedString(_ text: String, _ toLength: Int, truncating: Bool = false) -> String {
    if toLength > 0 {
      // Pad to the left of the string
      if text.count > toLength {
        // Hm... better to use suffix or prefix?
        return truncating ? String(text.suffix(toLength)) : text
      } else {
        return "".padding(toLength: toLength - text.count, withPad: " ", startingAt: 0) + text
      }
    } else if toLength < 0 {
      // Pad to the right of the string
      let maxLength = truncating ? -toLength : max(-toLength, text.count)
      return text.padding(toLength: maxLength, withPad: " ", startingAt: 0)
    } else {
      return text
    }
  }
  
  /// returns the log message based on the format pattern
  //swiftlint:disable cyclomatic_complexity
  //swiftlint:disable function_body_length
  //swiftlint:disable function_parameter_count
  func formatMessage(_ format: String, level: Logger.Level, msg: String, thread: String,
                     file: String, function: String, line: Int, context: LogContext = LogContext.app) -> String {
    
    var text = ""
    // Prepend a $I for 'ignore' or else the first character is interpreted as a format character
    // even if the format string did not start with a $.
    let phrases: [String] = ("$I" + format).components(separatedBy: "$")
    
    for phrase in phrases where !phrase.isEmpty {
      let (padding, offset) = parsePadding(phrase)
      let formatCharIndex = phrase.index(phrase.startIndex, offsetBy: offset)
      let formatChar = phrase[formatCharIndex]
      let rangeAfterFormatChar = phrase.index(formatCharIndex, offsetBy: 1)..<phrase.endIndex
      let remainingPhrase = phrase[rangeAfterFormatChar]
      
      switch formatChar {
      case "I":  // ignore
        text += remainingPhrase
      case "i":
        text += paddedString(self.moduleIdentification.identifier, padding) + remainingPhrase
      case "L":
        text += paddedString(levelWord(level), padding) + remainingPhrase
      case "M":
        text += paddedString(msg, padding) + remainingPhrase
      case "T":
        text += paddedString(thread, padding) + remainingPhrase
      case "N":
        // name of file without suffix
        text += paddedString(fileNameWithoutSuffix(file), padding) + remainingPhrase
      case "n":
        // name of file with suffix
        text += paddedString(fileNameOfFile(file), padding) + remainingPhrase
      case "F":
        text += paddedString(function, padding) + remainingPhrase
      case "l":
        text += paddedString(String(line), padding) + remainingPhrase
      case "D":
        text += paddedString(formatDate(String(remainingPhrase)), padding)
      case "d":
        text += remainingPhrase
      case "U":
        text += paddedString(uptime(), padding) + remainingPhrase
      case "Z":
        // start of datetime format in UTC timezone
        text += paddedString(formatDate(String(remainingPhrase), timeZone: "UTC"), padding)
      case "z":
        text += remainingPhrase
      case "C":
        // color code ("" on default)
        text += escape + colorForLevel(level) + remainingPhrase
      case "c":
        text += reset + remainingPhrase
      case "X":
        // add the context
        text += paddedString(context.rawValue, padding) + remainingPhrase
      default:
        text += phrase
      }
    }
    // right trim only
    return text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
  }
  //swiftlint:enable cyclomatic_complexity
  //swiftlint:enable function_body_length
  //swiftlint:enable function_parameter_count
  
  /// returns the string of a level
  func levelWord(_ level: Logger.Level) -> String {
    
    var str = ""
    
    switch level {
    case Logger.Level.debug:
      str = levelString.debug
      
    case Logger.Level.info:
      str = levelString.info
      
    case Logger.Level.warning:
      str = levelString.warning
      
    case Logger.Level.error:
      str = levelString.error
      
    default:
      // Verbose is default
      str = levelString.verbose
    }
    return str
  }
  
  /// returns color string for level
  func colorForLevel(_ level: Logger.Level) -> String {
    var color = ""
    
    switch level {
    case Logger.Level.debug:
      color = levelColor.debug
      
    case Logger.Level.info:
      color = levelColor.info
      
    case Logger.Level.warning:
      color = levelColor.warning
      
    case Logger.Level.error:
      color = levelColor.error
      
    default:
      color = levelColor.verbose
    }
    return color
  }
  
  /// returns the filename of a path
  func fileNameOfFile(_ file: String) -> String {
    let fileParts = file.components(separatedBy: "/")
    if let lastPart = fileParts.last {
      return lastPart
    }
    return ""
  }
  
  /// returns the filename without suffix (= file ending) of a path
  func fileNameWithoutSuffix(_ file: String) -> String {
    let fileName = fileNameOfFile(file)
    
    if !fileName.isEmpty {
      let fileNameParts = fileName.components(separatedBy: ".")
      if let firstPart = fileNameParts.first {
        return firstPart
      }
    }
    return ""
  }
  
  /// returns a formatted date string
  /// optionally in a given abbreviated timezone like "UTC"
  func formatDate(_ dateFormat: String, timeZone: String = "") -> String {
    if !timeZone.isEmpty {
      formatter.timeZone = TimeZone(abbreviation: timeZone)
    }
    formatter.dateFormat = dateFormat
    //let dateStr = formatter.string(from: NSDate() as Date)
    let dateStr = formatter.string(from: Date())
    return dateStr
  }
  
  /// returns a uptime string
  func uptime() -> String {
    let interval = Date().timeIntervalSince(startDate)
    
    let hours = Int(interval) / 3600
    let minutes = Int(interval / 60) - Int(hours * 60)
    let seconds = Int(interval) - (Int(interval / 60) * 60)
    let milliseconds = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)
    
    return String(format: "%0.2d:%0.2d:%0.2d.%03d", arguments: [hours, minutes, seconds, milliseconds])
  }
  
  /// checks if level is at least minLevel or if a minLevel filter for that path does exist
  /// returns boolean and can be used to decide if a message should be logged or not
  func shouldLevelBeLogged(_ level: Logger.Level, path: String,
                           function: String, message: String? = nil) -> Bool {
    
    if level.rawValue >= minLevel.rawValue {
      if debugPrint {
        print("filters is empty and level >= minLevel")
      }
      return true
    } else {
      if debugPrint {
        print("filters is empty and level < minLevel")
      }
      return false
    }
  }
}

public func == (lhs: LoggerDestination, rhs: LoggerDestination) -> Bool {
  return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}
