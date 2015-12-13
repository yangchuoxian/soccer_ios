//
//  AppDelegate.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/28.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

@objc class AppDelegate: UIResponder, UIApplicationDelegate, BMKGeneralDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate {
    
    var mapManager: BMKMapManager?
    var window: UIWindow?
    var username: String?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // clear push notification badge when opened app
        Toolbox.clearLocalAndRemoteNotificationCount()
        // the following tracks to see if there are any push notifications, if push notifications arrived at a time when the app is NOT RUNNING AT ALL, NOT EVEN IN BACKGROUND OR SUSPENDED, this is where the received push notification gets handled, for other app status, the received push notifications are handled in didReceiveRemoteNotification: fetchCompletionHandler()
        if launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] != nil {
            // there are remote notification launch options ONLY WHEN user tapped ONE of the push notification to launch the app
            let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject: AnyObject]
            if userInfo != nil {
                self.handlePushNotification(userInfo!)
            }
        }
        // set up iVersion by assigning app store id to it
        iVersion.sharedInstance().appStoreID = AppStoreId
        // Override point for customization after application launch
        // initiate BaiduMapManager
        self.mapManager = BMKMapManager()
        self.mapManager!.start(ApiKeys.BaiduMap.rawValue, generalDelegate: self)
        // setup UMENG social share SDK
        UMSocialData.setAppKey(ApiKeys.UMeng.rawValue)
        // setup Weixin social share SDK
        UMSocialWechatHandler.setWXAppId(ApiKeys.WXAppId.rawValue, appSecret: ApiKeys.WXAppSecret.rawValue, url: "http://www.umeng.com/social")
        // setup pgyer beta test SDK and enable check for update function
        // PgyManager.sharedPgyManager().startManagerWithAppId(ApiKeys.PGY.rawValue)
        // PgyManager.sharedPgyManager().checkUpdate()
        // PgyManager.sharedPgyManager().enableFeedback = true
        
        // Initialize Reachability
        let reachability = Reachability(hostname: TestConnectivityHostname)
        // Start Monitoring the mobile device reachability status,
        // if the device switches between connected and disconnected from online
        // a notification will be sent
        reachability.startNotifier()
        // listen to reachable/unreachablie message sent by Reachability
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityDidChange:", name: kReachabilityChangedNotification, object: nil)
        
        // Set up push notification
        if #available(iOS 8.0, *) {
            let types: UIUserNotificationType = [UIUserNotificationType.Sound, UIUserNotificationType.Badge, UIUserNotificationType.Alert]
            let notificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
            application.registerUserNotificationSettings(notificationSettings)
        } else {
            let types: UIRemoteNotificationType = [UIRemoteNotificationType.Badge, UIRemoteNotificationType.Sound, UIRemoteNotificationType.Alert]
            application.registerForRemoteNotificationTypes(types)
        }
        
        // check to see if it is necessary to show tutorial screen pages by checking saved version number in userDefaults
        let savedVersion = NSUserDefaults.standardUserDefaults().stringForKey("version")
        if Toolbox.isStringValueValid(savedVersion) && savedVersion == AppVersion {   // this app has been launched before and so far has NOT been updated to a newer version
            // check if username and password is saved in keychain, if so, login automatically
            let userCredential = Toolbox.getUserCredential()
            if userCredential != nil {    // username and loginToken already stored in keychain, get user info and then change rootViewController to mainTabBarViewController
                let currentUserId = userCredential!["currentUserId"]
                // set post parameters
                let getParametersString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("?id=\(currentUserId!)")
                let userInfoResponseData = Toolbox.syncHttpGetFromURL("\(URLGetUserInfo)\(getParametersString)&isAutoLogin=true")
                if userInfoResponseData != nil {
                    let userJSON = (try? NSJSONSerialization.JSONObjectWithData(userInfoResponseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
                    if userJSON != nil {    // get user info succeeded
                        Singleton_CurrentUser.sharedInstance.processUserLogin(userJSON!)
                        return true
                    }
                }
            }
            // automatically login failed, go to login view controller
            Toolbox.switchToLoginViewController()
        } else {    // either this is the first time app is launched, or the app has updated to a newer version, either way, we should prompt the user with welcome/tutorial screen
            // NOTE: the startup view controller is already set to tutorial page view controller
            NSUserDefaults.standardUserDefaults().setObject(AppVersion, forKey: "version")
        }
        return true
    }
    
    /**
     * iOS8 can receive silent notificaions without asking for permission. Call  - (void)registerForRemoteNotifications. After this application:didRegisterForRemoteNotificationsWithDeviceToken: will be called
     */
    @available(iOS 8.0, *)
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // save deviceToken in userDefaults, when user submit login info or registering new user, this device token will be submitted as well
        let tempDeviceToken  = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
        let deviceTokenString  = tempDeviceToken.stringByReplacingOccurrencesOfString(" ", withString: "")
        NSUserDefaults.standardUserDefaults().setObject(deviceTokenString, forKey: "deviceToken")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        // print out error message if any
        print(error)
    }
    
    /**
     * This method gets called when push notification received while the app is running on the foreground or on the background
     */
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if application.applicationState == .Inactive {
            completionHandler(.NewData)
        } else if application.applicationState == .Background {
            completionHandler(.NewData)
        } else {
            completionHandler(.NewData)
        }
        
        self.handlePushNotification(userInfo)
    }
    
    func reachabilityDidChange(notification: NSNotification) {
        let reachability = notification.object as! Reachability
        if reachability.isReachable() {
            // connect to server socket.io and subscribe to message event
            Singleton_SocketManager.sharedInstance.connectToSocket()
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        let socketManager = Singleton_SocketManager.sharedInstance
        if socketManager.socket.status == .Connected {
            socketManager.socket.close()
            socketManager.intentionallyDisconnected = true
        }
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.   
        let socketManager = Singleton_SocketManager.sharedInstance
        if socketManager.socket.status == .Connected {
            socketManager.socket.close()
            socketManager.intentionallyDisconnected = true
        }
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // clear push notification badge when opened app
        Toolbox.clearLocalAndRemoteNotificationCount()

        if Singleton_CurrentUser.sharedInstance.userId != nil {
            let getParametersString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("?id=\(Singleton_CurrentUser.sharedInstance.userId!)")
            let connection = Toolbox.asyncHttpGetFromURL("\(URLGetUserInfo)\(getParametersString)&isAutoLogin=true", delegate: self)
            if connection == nil {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络无法连接")
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        // http response for automatic login
        // if login succeeded, response from server should be user info JSON data, so retrieve username from this JSON data to see if login is successful
        let userInfo = (try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if userInfo != nil {    // get user info succeeded
            // save user info to singleton currentUser instance
            Singleton_CurrentUser.sharedInstance.getUserInfoFrom(userInfo!)
            // connect to server socket.io and subscribe to message event
            Singleton_SocketManager.sharedInstance.connectToSocket()
        }
    }
    
    func handlePushNotification(userInfo: [NSObject: AnyObject]) {
        let pushNotificationEventType = userInfo["event"] as? String
        if pushNotificationEventType == "logout" {  // user has logged in from another device, log the user out from this device
            Singleton_CurrentUser.sharedInstance.forcedLogout()
        } else if pushNotificationEventType == "message" {  // received a new message, save it to local database
            let messageInfo = userInfo["message"] as! [String: AnyObject]
            let message = Message(messageInfo: messageInfo)
            Message.saveMessageInDatabase(message)
            // handles system message and send local notification to update corresponding view controllers
            Message.sendLocalNotificationRegardingSystemMessage(messageInfo)
        }
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return UMSocialSnsService.handleOpenURL(url)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return UMSocialSnsService.handleOpenURL(url)
    }
    
}
