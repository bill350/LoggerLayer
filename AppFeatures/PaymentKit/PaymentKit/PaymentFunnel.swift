// PaymentKit
// Copyright © 2018 Back Market. All rights reserved.

import Foundation
import Logger

public final class PaymentFunnel {
  
  private var timer: Timer?
  
  private var randomContexts = [PaymentModule.Log.defaultContext,
                        PaymentModule.Log.paypalContext,
                        PaymentModule.Log.creditCardContext]
  
  private var randomLevels = [Logger.Level.verbose,
                      .error,
                      .warning,
                      .debug,
                      .info]
  
  public init() {}
  
  public func doSomeStuffRandomly() {
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
      let randomLevel = self.randomLevels.randomElement()
      let randomContext = self.randomContexts.randomElement()
      
      if let randomLevel = randomLevel, let randomContext = randomContext {
        PaymentModule.logger.custom(level: randomLevel, message: "Here a bunny 🐰", context: randomContext)
      }
    })
  }
}
