//
//  AppDelegate.swift
//  IOS2-MapKit
//
//  Created by Daniel Carvalho on 22/02/22.
//

import UIKit

// THEORY: how does an iOS app even start?
// `@main` marks the entry point of the whole program — the equivalent of
// `func main()` in other languages. When the app launches, iOS creates
// exactly one AppDelegate and calls its lifecycle methods below in order.
// AppDelegate handles app-wide events (launch, background/foreground
// transitions across the WHOLE app). Since iOS 13, each individual window/
// screen's lifecycle is handled by a separate SceneDelegate (see
// SceneDelegate.swift) — that split exists to support multiple windows on
// iPad, even though this project only ever has one.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

