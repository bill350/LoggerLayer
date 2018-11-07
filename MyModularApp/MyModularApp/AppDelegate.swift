// MyModularApp
// Copyright © 2018 Back Market. All rights reserved.

import UIKit
import PaymentKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  let paymentFunnel = PaymentFunnel()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    PaymentModule.configure()
    self.paymentFunnel.doSomeStuffRandomly()
    // Override point for customization after application launch.

    return true
  }

}
