//
//  Singleton_CurrentUser.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class Singleton_CurrentUser: NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
   
    static let sharedInstance = Singleton_CurrentUser()
    
    var userId: String?
    var username: String?
    var password: String?
    var email: String?
    var name: String?
    var introduction: String?
    var balance: String?
    var points: String?
    var phoneNumber: String?
    var location: String?
    var height: String?
    var weight: String?
    var position: String?
    var gender: String?
    var careerAge: String?
    var dateOfBirth: String?
    var averageAbility: String?
    var numToReviewOnAverageAbility: String?
    var speed: String?
    var numToReviewOnSpeed: String?
    var jumpAbility: String?
    var numToReviewOnJumpAbility: String?
    var explosiveForceAbility: String?
    var numToReviewOnExplosiveForceAbility: String?
    var conscious: String?
    var numToReviewOnConscious: String?
    var cooperation: String?
    var numToReviewOnCooperation: String?
    var personality: String?
    var numToReviewOnPersonality: String?
    var isLookingForTeam = ""
    
    var HUD: MBProgressHUD?
    var currentUpdatingInfoName: String?
    var updatedUserInfoValue: String?
    
    var responseData: NSMutableData? = NSMutableData()
    
    func getUserInfoFrom(_ userInfo: [AnyHashable: Any]) {
        self.userId = userInfo["id"] as? String
        // remmeber current user id in userDefaults
        UserDefaults.standard.set(self.userId, forKey: "currentUserId")
        self.username = userInfo["username"] as? String
        if let email = userInfo["email"] as? String {
            self.email = email
        }
        if let introduction = userInfo["introduction"] as? String {
            self.introduction = introduction
        } else {
            self.introduction = ""
        }
        if let name = userInfo["name"] as? String {
            self.name = name
        } else {
            self.name = ""
        }
        if let balance = userInfo["balance"] as? String {
            self.balance = balance
        } else {
            self.balance = ""
        }
        if let points = userInfo["points"] as? String {
            self.points = points
        } else {
            self.points = ""
        }
        if let phoneNumber = userInfo["phoneNumber"] as? String {
            self.phoneNumber = phoneNumber
        } else if let phoneNumber = userInfo["phoneNumber"] as? Int {
            self.phoneNumber = "\(phoneNumber)"
        } else {
            self.phoneNumber = ""
        }
        if let location = userInfo["location"] as? String {
            self.location = location
        } else {
            self.location = ""
        }
        if let height = userInfo["height"] as? String {
            self.height = height
        } else {
            self.height = ""
        }
        if let weight = userInfo["weight"] as? String {
            self.weight = weight
        } else {
            self.weight = ""
        }
        if let careerAge = userInfo["careerAge"] as? String {
            self.careerAge = careerAge
        } else {
            self.careerAge = ""
        }
        if let averageAbility = userInfo["averageAbility"] as? String {
            self.averageAbility = averageAbility
        } else {
            self.averageAbility = "0.0"
        }
        if let numToReviewOnAverageAbility = userInfo["numToReviewOnAverageAbility"] as? String {
            self.numToReviewOnAverageAbility = numToReviewOnAverageAbility
        } else {
            self.numToReviewOnAverageAbility = "0"
        }
        if let speed = userInfo["speed"] as? String {
            self.speed = speed
        } else {
            self.speed = "0.0"
        }
        if let numToReviewOnSpeed = userInfo["numToReviewOnSpeed"] as? String {
            self.numToReviewOnSpeed = numToReviewOnSpeed
        } else {
            self.numToReviewOnSpeed = "0"
        }
        if let jumpAbility = userInfo["jumpAbility"] as? String {
            self.jumpAbility = jumpAbility
        } else {
            self.jumpAbility = "0.0"
        }
        if let numToReviewOnJumpAbility = userInfo["numToReviewOnJumpAbility"] as? String {
            self.numToReviewOnJumpAbility = numToReviewOnJumpAbility
        } else {
            self.numToReviewOnJumpAbility = "0"
        }
        if let explosiveForceAbility = userInfo["explosiveForceAbility"] as? String {
            self.explosiveForceAbility = explosiveForceAbility
        } else {
            self.explosiveForceAbility = "0.0"
        }
        if let numToReviewOnExplosiveForceAbility = userInfo["numToReviewOnExplosiveForceAbility"] as? String {
            self.numToReviewOnExplosiveForceAbility = numToReviewOnExplosiveForceAbility
        } else {
            self.numToReviewOnExplosiveForceAbility = "0"
        }
        if let conscious = userInfo["conscious"] as? String {
            self.conscious = conscious
        } else {
            self.conscious = "0.0"
        }
        if let numToReviewOnConscious = userInfo["numToReviewOnConscious"] as? String {
            self.numToReviewOnConscious = numToReviewOnConscious
        } else {
            self.numToReviewOnConscious = "0"
        }
        if let cooperation = userInfo["cooperation"] as? String {
            self.cooperation = cooperation
        } else {
            self.cooperation = "0.0"
        }
        if let numToReviewOnCooperation = userInfo["numToReviewOnCooperation"] as? String {
            self.numToReviewOnCooperation = numToReviewOnCooperation
        } else {
            self.numToReviewOnCooperation = "0"
        }
        if let personality = userInfo["personality"] as? String {
            self.personality = personality
        } else {
            self.personality = "0.0"
        }
        if let numToReviewOnPersonality = userInfo["numToReviewOnPersonality"] as? String {
            self.numToReviewOnPersonality = numToReviewOnPersonality
        } else {
            self.numToReviewOnPersonality = "0"
        }
        if let dateOfBirth = userInfo["dateOfBirth"] as? String {
            self.dateOfBirth = dateOfBirth
        } else {
            self.dateOfBirth = ""
        }
        if let position = userInfo["position"] as? String {
            self.position = position
        } else {
            self.position = ""
        }
        if let gender = userInfo["gender"] as? String {
            self.gender = gender
        } else {
            self.gender = ""
        }
        if let isLookingForTeam = userInfo["isLookingForTeam"] as? String {
            self.isLookingForTeam = isLookingForTeam
        }
    }
    
    func resetCurrentUserInfo() {
        self.userId = nil
        self.username = nil
        self.email = nil
        self.name = nil
        self.introduction = nil
        self.balance = nil
        self.points = nil
        self.phoneNumber = nil
        self.location = nil
        self.height = nil
        self.weight = nil
        self.position = nil
        self.gender = nil
        self.careerAge = nil
        self.dateOfBirth = nil
        self.averageAbility = nil
        self.numToReviewOnAverageAbility = nil
        self.speed = nil
        self.numToReviewOnSpeed = nil
        self.jumpAbility = nil
        self.numToReviewOnJumpAbility = nil
        self.explosiveForceAbility = nil
        self.numToReviewOnExplosiveForceAbility = nil
        self.conscious = nil
        self.numToReviewOnConscious = nil
        self.cooperation = nil
        self.numToReviewOnCooperation = nil
        self.personality = nil
        self.numToReviewOnPersonality = nil
    }
    
    func updateUserInfo(_ infoName: String, infoValue: AnyObject) {
        var postParamsString: String
        if infoName == "location" {
            // when updating user location, other than the user location address, the frontend also needs to submit the latitude and longitude of user current location,
            // the server will need the coordinate to calculate geohash string to get nearby users
            let locationInfo = infoValue as! NSDictionary
            postParamsString = infoName + "=" + (locationInfo.object(forKey: "location") as! String)
            postParamsString += "&latitude=" + (locationInfo.object(forKey: "latitude") as! String)
            postParamsString += "&longitude=" + (locationInfo.object(forKey: "longitude") as! String)
            postParamsString += "&id=" + self.userId!
            self.updatedUserInfoValue = locationInfo.object(forKey: "location") as? String
        } else {
            postParamsString = infoName + "=" + (infoValue as! String) + "&id=" + self.userId!
            self.updatedUserInfoValue = infoValue as? String
        }
        let connection = Toolbox.asyncHttpPostToURL(URLChangeUserInfo, parameters:postParamsString, delegate: self)
        self.currentUpdatingInfoName = infoName
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func updateUserPassword(_ oldPassword: String, newPassword: String, confirmPassword: String) {
        // get current view controller
        let postParamsString = "oldPassword=" + oldPassword + "&newPassword=" + newPassword + "&confirmPassword=" + confirmPassword + "&id=" + self.userId!
        let connection = Toolbox.asyncHttpPostToURL(URLChangePassword, parameters: postParamsString, delegate: self)

        self.currentUpdatingInfoName = "password"
        self.updatedUserInfoValue = newPassword
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        if responseStr == "OK" {    // user info successfully updated
            if self.currentUpdatingInfoName == "username" {
                self.username = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "email" {
                self.email = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "name" {
                self.name = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "phoneNumber" {
                self.phoneNumber = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "location" {
                self.location = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "gender" {
                self.gender = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "dateOfBirth" {
                self.dateOfBirth = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "position" {
                self.position = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "height" {
                self.height = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "weight" {
                self.weight = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "introduction" {
                self.introduction = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "careerAge" {
                self.careerAge = self.updatedUserInfoValue
            } else if self.currentUpdatingInfoName == "password" {
                self.password = self.updatedUserInfoValue
                // send message to notify that password is updated
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: "settingsInstructionComplete"),
                    object: ["settings": "changePassword"]
                )
            }
            // send message to notify that user info is updated
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "userInfoUpdated"),
                object: ["userInfoIndex": self.currentUpdatingInfoName!]
            )
        } else {                                    // user info update failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: (responseStr as! String))
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func logout() {
        // disconnect socket
        let socketManager = Singleton_SocketManager.sharedInstance
        if socketManager.socket.status == .connected {
            socketManager.socket.close()
            socketManager.intentionallyDisconnected = true
        }
        // remove the login credentials saved in keychain
        let keychainItem = KeychainItemWrapper(identifier: "SoccerAppLogin", accessGroup: nil)
        keychainItem?.resetKeychainItem()
        // reset existing currentUser instance value
        self.resetCurrentUserInfo()
        // change rootViewController to loginViewController
        let storyboard = UIStoryboard(name: StoryboardNames.Account.rawValue, bundle: nil)
        let rootViewController = storyboard.instantiateViewController(withIdentifier: "accountNavigationViewController") 
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
    }
    
    func forcedLogout() {
        self.logout()
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "用户已在另一台设备登录")
    }

    func processUserLogin(_ userJSON: [AnyHashable: Any]) {
        // save user info to singleton currentUser instance
        Singleton_CurrentUser.sharedInstance.getUserInfoFrom(userJSON)
        // store username and password in keychain
        // connect to server socket.io and subscribe to message event
        Singleton_SocketManager.sharedInstance.connectToSocket()
        // remember current user id and login token in keyChain
        let loginToken = userJSON["loginToken"] as? String
        if Toolbox.isStringValueValid(loginToken) {
            Toolbox.saveUserCredential(
                Singleton_CurrentUser.sharedInstance.userId!,
                loginToken: (userJSON["loginToken"] as! String)
            )
        }
        // remember the user with id as last login user in userDefaults, so as to show his/her avatar in loginViewController
        UserDefaults.standard.set(self.userId!, forKey: "lastLoginUserId")
        
        // change rootViewController to mainTabBarViewController
        let storyboard = UIStoryboard(name: StoryboardNames.MainTab.rawValue, bundle: nil)
        let rootViewController = storyboard.instantiateInitialViewController() as! UITabBarController
        if UIApplication.shared.keyWindow != nil {
            UIApplication.shared.keyWindow!.rootViewController = rootViewController
        } else {
            UIApplication.shared.delegate?.window??.rootViewController = rootViewController
        }
        
    }
    
}
