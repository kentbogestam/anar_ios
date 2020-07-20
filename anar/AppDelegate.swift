//
//  AppDelegate.swift
//  anar
//
//  Created by Kent Bogestam on 2018-12-21.
//  Copyright © 2018 Kent Bogestam. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        App42API.initialize(withAPIKey: Constant.APP42_APP_KEY, andSecretKey: Constant.APP42_SECRET_KEY)
//        
//        registerForPushNotifications()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func registerForPushNotifications() {
      UNUserNotificationCenter.current() // 1
        .requestAuthorization(options: [.alert, .sound, .badge]) {
            [weak self] granted, error in
              
            debugPrint("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        debugPrint("Device Token: \(token)")
        
        registerDeviceTokenInApp42Server(token: token)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint("Failed to register: \(error)")
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            debugPrint("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func registerDeviceTokenInApp42Server(token: String) {
        let userName = "iOS_User"
        
        let pushNotificationService = App42API.buildPushService() as? PushNotificationService
        
        pushNotificationService?.registerDeviceToken(token, withUser:userName, completionBlock: { (success, response, exception) -> Void in
            if(success) {
                let pushNotification = response as! PushNotification
                print(pushNotification.userName, pushNotification.deviceToken)
                let alert = UIAlertController.init(title: "Token", message: "\(token)", preferredStyle: .alert)
                let action = UIAlertAction(title: "Copy", style: .cancel) { (UIAlertAction) in
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = "\(token)"
                }
                alert.addAction(action)
                DispatchQueue.main.async {
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
                
            } else {
                print(exception?.reason! ?? "", exception?.appErrorCode ?? "", exception?.httpErrorCode ?? "", exception?.userInfo! ?? "")
                let msg = "\(exception?.reason! ?? "")"
                let alert = UIAlertController.init(title: "Error", message: "\(msg)", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .cancel)
                alert.addAction(action)
                DispatchQueue.main.async {
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
                
            }
            
        })
    }
}

