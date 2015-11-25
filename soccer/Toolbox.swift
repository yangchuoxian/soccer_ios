//
//  ToolBox.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/4.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class Toolbox: NSObject, MBProgressHUDDelegate {
    
    static func isStringValueValid(value: String?) -> Bool {
        if value == nil {
            return false
        }
        if (value!).characters.count == 0 {
            return false
        }
        if value == "<null>" {
            return false
        }
        return true
    }
    
    /**
     * Given a date string, check to see if it is the format of "yyyy-MM-dd'T'HH:mm:ss.SSSz"
     */
    static func isDateStringServerDateFormat(dateString: String) -> Bool {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
        let dateTimeString = dateFormatter.dateFromString(dateString)
        if dateTimeString != nil {
            return true
        }
        return false
    }
    
    /**
     * format time string like 2015-03-26T04:19:25.583Z to 2015-03-26,
     * and if the date is today and shouldGetHourAndMinute is YES, then show 04:19 instead
     * otherwise just return 2015-03-26
     */
    static func formatTimeString(timeString: String, shouldGetHourAndMinute getHourAndMinute: Bool) -> String {
        if !Toolbox.isDateStringServerDateFormat(timeString) {
            return timeString
        }
        let date = NSDate(dateTimeString: timeString)
        // get today's date
        let todayDate = NSDate()
        if date.isTheSameDayAs(todayDate) && getHourAndMinute {
            return date.getTimeString()
        } else {
            return date.getDateString()
        }
    }
    
    static func showCustomAlertViewWithImage(imageName: String, title t: String) {
        var HUD = MBProgressHUD(view: Toolbox.getCurrentViewController()?.view)
        Toolbox.getCurrentViewController()?.view.addSubview(HUD)
        HUD.customView = UIImageView(image: UIImage(named: imageName))
        // Set custom view mode
        HUD.mode = .CustomView
        HUD.labelText = t
        HUD.show(true)
        // hide and remove HUD view a while after
        HUD.hide(true, afterDelay: 1)
        HUD = nil
    }
    
    static func setupCustomProcessingViewWithTitle(title t: String?) -> MBProgressHUD {
        let HUD = MBProgressHUD(view: Toolbox.getCurrentViewController()?.view)
        if Toolbox.isStringValueValid(t) {
            HUD.labelText = t
        }
        Toolbox.getCurrentViewController()?.view.addSubview(HUD)
        HUD.show(true)
        return HUD
    }
    
    /**
     * For http requests sent from mobile native app, the server validates whether
     * the request is sent by logged in user by checking the login token and user id,
     * if it matches, the request can go through, otherwise, it is an illegal request
     */
    static func addLoginTokenAndCurrentUserIdToHttpRequestParameters(urlOrPostParameters: String) -> String {
        let userCredential = Toolbox.getUserCredential()
        if userCredential != nil {
            let loginToken = userCredential!["loginToken"]
            let currentUserId = userCredential!["currentUserId"]
            return urlOrPostParameters + "&loginToken=\(loginToken!)&currentUserId=\(currentUserId!)"
        } else {
            return urlOrPostParameters
        }
    }
    
    /**
     * Add device token and device type parameter to http request parameter string if they exist, 
     * otherwise, add NOTHING
     */
    static func addDeviceIDAndDeviceTypeToHttpRequestParameters(urlOrPostParameters: String) -> String {
        let deviceTokenString = NSUserDefaults.standardUserDefaults().stringForKey("deviceToken")
        if Toolbox.isStringValueValid(deviceTokenString) {
            return urlOrPostParameters + "&deviceID=\(deviceTokenString!)&deviceType=\(DeviceType.IOS.rawValue)"
        } else {
            return urlOrPostParameters
        }
    }
    
    /* ASYNCHRONOUS http get request */
    static func asyncHttpGetFromURL(url: String, delegate d: AnyObject) -> NSURLConnection? {
        let completeUrl = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(url)
        let url_encoded = completeUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

        let request = NSMutableURLRequest(URL: NSURL(string: url_encoded!)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: TimeIntervals.HttpRequestTimeout.rawValue)
        request.HTTPMethod = "GET"
        return NSURLConnection(request: request, delegate: d)
    }
    
    /* ASYNCHRONOUS http post request */
    static func asyncHttpPostToURL(url: String, parameters postParametersString: String, delegate d: AnyObject?) -> NSURLConnection? {
        let completePostParamsString = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(postParametersString)
        let postParametersStringThatEscapedSpecialCharacters = completePostParamsString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        // set post parameters
        let postParametersData = postParametersStringThatEscapedSpecialCharacters!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let postParametersLength = "\((postParametersStringThatEscapedSpecialCharacters!).characters.count)"
        // http request to get service agreement content from server
        let url_encoded = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let request = NSMutableURLRequest(URL: NSURL(string: url_encoded!)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: TimeIntervals.HttpRequestTimeout.rawValue)
        request.HTTPMethod = "POST"
        request.setValue(postParametersLength, forHTTPHeaderField: "Content-Length")
        request.HTTPBody = postParametersData
        
        // start asynchronous http request
        return NSURLConnection(request: request, delegate: d)
    }
    
    /* SYNCHRONOUS http get request */
    static func syncHttpGetFromURL(url: String) -> NSData? {
        let completeUrl = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(url)
        let url_encoded = completeUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let request = NSMutableURLRequest(URL: NSURL(string: url_encoded!)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: TimeIntervals.HttpRequestTimeout.rawValue)
        request.HTTPMethod = "GET"
        var response: NSURLResponse?
        var error: NSError?
        let responseData: NSData?
        do {
            responseData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        } catch let error1 as NSError {
            error = error1
            responseData = nil
        }
        if error != nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "无法连接服务器")
            return nil
        }
        return responseData
    }
    
    /* SYNCHRONOUS http post request */
    static func syncHttpPost(url: String, parameters postParametersString: String) -> NSData? {
        let completePostParamsString = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(postParametersString)
        let postParametersStringThatEscapedSpecialCharacters = completePostParamsString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let postParametersData = postParametersStringThatEscapedSpecialCharacters!.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        let postParametersLength = "\(completePostParamsString.characters.count)"
        // http request to get service agreement content from server
        let url_encoded = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let request = NSMutableURLRequest(URL: NSURL(string: url_encoded!)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: TimeIntervals.HttpRequestTimeout.rawValue)
        request.HTTPMethod = "POST"
        request.setValue(postParametersLength, forHTTPHeaderField: "Content-Length")
        request.HTTPBody = postParametersData
        
        var response: NSURLResponse?
        var error: NSError?
        let responseData: NSData?
        do {
            responseData = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        } catch let error1 as NSError {
            error = error1
            responseData = nil
        }
        if error != nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "无法连接服务器")
            return nil
        }
        return responseData
    }
    
    /**
     * Asynchronously download avatar image from url and save it as a file locally.
     * The name of avatar file is always <user id>.png
     */
    static func asyncDownloadAvatarImageForModelId(modelId: String, avatarType aType: AvatarType, completionBlock: ((Bool, UIImage?) -> Void)?) {
        var urlWithParams: String
        if aType == .User {   // the avatar is for user
            urlWithParams = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(URLUserAvatar + modelId)
        } else {                                // the avatar is for team
            urlWithParams = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(URLTeamAvatar + modelId)
        }
        let request = NSMutableURLRequest(URL: NSURL(string: urlWithParams)!)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
            response, data, error in
            let httpResponse = response as? NSHTTPURLResponse
            if httpResponse != nil {
                if httpResponse?.statusCode == HttpStatusCode.OK.rawValue {  // avatar download succeeded
                    let image = UIImage(data: data!)
                    // save successfully downloaded user avatar to local app directory with name <user id>.png
                    if image != nil {
                        self.saveAvatarImageLocally(image!, modelId: modelId)
                        completionBlock!(true, image)
                    } else {
                        completionBlock!(false, nil)
                    }
                } else { // avatar download failed, probably because the user has not setup his/her avatar
                    completionBlock!(false, nil)
                }
            } else {
                completionBlock!(false, nil)
            }
        })
    }
    
    static func uploadImageToURL(url: String, image i: UIImage, parameters pDictionary: [NSObject: AnyObject]?, delegate d: AnyObject) -> NSURLConnection? {
        let httpDataBoundary = "---------------------------14737809831466499882746641449"

        let imageData = UIImageJPEGRepresentation(i, 1.0)
        let imageExtension = ".jpg"
        let contentType = "multipart/form-data; boundary=\(httpDataBoundary)"
        
        let body = NSMutableData()
        if pDictionary != nil {
            for (name, value) in pDictionary! {
                body.appendData("--\(httpDataBoundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData("\(value)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        
        // get login token and currentUserId from userDefaults
        let credentialInfo = Toolbox.getUserCredential()
        if credentialInfo != nil {
            for (name, value) in credentialInfo! {
                body.appendData("--\(httpDataBoundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData("\(value)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        
        body.appendData("\r\n--\(httpDataBoundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition: form-data; name=\"avatar\"; filename=\"user_avatar\(imageExtension)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: application/octet-stream\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        body.appendData(NSData(data: imageData!))
        body.appendData("\r\n--\(httpDataBoundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let url_encoded = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let request = NSMutableURLRequest(URL: NSURL(string: url_encoded!)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: TimeIntervals.ImageUploadTimeout.rawValue)
        request.HTTPMethod = "POST"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        // set the content-length
        let postLength = "\(body.length)"
        
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.HTTPBody = body
        // start asynchronous http request
        return NSURLConnection(request: request, delegate: d)
    }
    
    /**
    Load avatar image to designated image view
    1. If the avatar image exists locally, load it from local file
    2. If the avatar image DOES NOT exist, load it ASYNCHRONOUSLY from URL and the save it locally

    - parameter modelId:   the team or user id
    - parameter imageView: the imageView to show the avatar
    - parameter aType:     whether the avatar is for team or user
    */
    static func loadAvatarImage(modelId: String, toImageView imageView: UIImageView, avatarType aType: AvatarType) {
        // load avatar image
        let avatarPath = Toolbox.getAvatarImagePathForModelId(modelId)
        if avatarPath != nil {    // current user avatar image file exists locally
            imageView.image = UIImage(contentsOfFile: avatarPath!)
        } else {                        // current user avatar image file not exists, load it from url
            // set the current user avatar to local default avatar,
            // in the mean time, start to download the avatar asynchronously,
            // if the avatar image doesn't exist even on server side, then use the local default avatar instead
            imageView.image = UIImage(named: "avatar")
            Toolbox.asyncDownloadAvatarImageForModelId(modelId, avatarType: aType, completionBlock: {
                succeeded, image in
                if (succeeded) {
                    imageView.image = image
                }
                return
            })
        }
    }
    
    /*
     * Get avatar image path for user based on its model id,
     * also check if that avata image file exists,
     * if not, return nil, if it does, return the file path
     * NOTE: model id is the mongodb id of that corresponding record saved in server,
     * it could represents either a user or a team, since both user and team are allowed
     * to have an avatar
     */
    static func getAvatarImagePathForModelId(modelId: String) -> String? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let avatarFilePath = "\(documentsPath)/\(modelId).png"
        let avatarFileExists = NSFileManager.defaultManager().fileExistsAtPath(avatarFilePath)
        if avatarFileExists {
            return avatarFilePath
        } else {
            return nil
        }
    }
    
    static func saveAvatarImageLocally(avatarImage: UIImage, modelId mId: String) -> Bool {
        let imageData = UIImagePNGRepresentation(avatarImage)
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let imagePath = "\(documentsDirectory)/\(mId).png"
        
        return imageData!.writeToFile(imagePath, atomically: false)
    }
    
    /**
     * With dictionary or array data structure, this function converts it to JSON string as http post parameters
     */
    static func convertDictionaryOrArrayToJSONString(arrayOrDictionary: AnyObject) -> String {
        let JSONData: NSData?
        do {
            JSONData = try NSJSONSerialization.dataWithJSONObject(arrayOrDictionary, options: NSJSONWritingOptions.PrettyPrinted)
        } catch {
            JSONData = nil
        }
        let JSONString = NSString(data: JSONData!, encoding: NSUTF8StringEncoding)
        return JSONString as! String
    }
    
    /**
     * Function to store username and password in keychain
     */
    static func saveUserCredential(currentUserId: String, loginToken token: String) {
        // store username and password in keychain
        var keychainItem = KeychainItemWrapper(identifier: "SoccerAppLogin", accessGroup: nil)
        keychainItem.setObject(currentUserId, forKey: kSecAttrAccount)
        keychainItem.setObject(token, forKey: kSecValueData)
        keychainItem = nil
    }
    
    /**
     * Retrieve login credentials saved in keychain
     */
    static func getUserCredential() -> [String: String]? {
        let keychainItem = KeychainItemWrapper(identifier: "SoccerAppLogin", accessGroup: nil)
        let currentUserId = keychainItem.objectForKey(kSecAttrAccount) as? String
        let loginTokenData = keychainItem.objectForKey(kSecValueData) as? NSData
        var loginToken: NSString?
        if Toolbox.isStringValueValid(currentUserId) && loginTokenData != nil {
            loginToken = NSString(data: loginTokenData!, encoding: NSUTF8StringEncoding)
            return [
                "currentUserId": currentUserId!,
                "loginToken": loginToken as! String
            ]
        } else {
            return nil
        }
    }
    
    /* Create an image with given color */
    static func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    static func generateQRCodeWithString(string: String, scale s: CGFloat) -> UIImage? {
        let stringData = string.dataUsingEncoding(NSUTF8StringEncoding)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter!.setValue(stringData, forKey: "inputMessage")
        filter!.setValue("M", forKey: "inputCorrectionLevel")
        
        // Render the image into a CoreGraphics image
        let cgImage = CIContext(options: nil).createCGImage(filter!.outputImage!, fromRect: filter!.outputImage!.extent)
        
        //Scale the image usign CoreGraphics
        UIGraphicsBeginImageContext(CGSizeMake(filter!.outputImage!.extent.size.width * s, filter!.outputImage!.extent.size.width * s))
        let context = UIGraphicsGetCurrentContext()
        CGContextSetInterpolationQuality(context, CGInterpolationQuality.None)
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage)
        let preImage = UIGraphicsGetImageFromCurrentImageContext()
        //Cleaning up
        UIGraphicsEndImageContext()
        // Rotate the image
        return UIImage(CGImage: preImage.CGImage!, scale: preImage.scale, orientation: .DownMirrored)
    }
    
    /**
     * Get the topmost current showing view controller
     */
    static func getCurrentViewController() -> UIViewController? {
        // get current view controller
        if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            // topController should now be your topmost view controller
            return topController
        }
        return UIApplication.sharedApplication().delegate?.window??.rootViewController
    }
    
    static func toggleButton(button: UIButton, enabled e: Bool) {
        button.enabled = e
        if e {
            button.alpha = 1.0
        } else {
            button.alpha = 0.5
        }
    }
    
    /**
     * Get rid of blank and new line characters at the front and end of strings, 
     * also remove special character '&'
     */
    static func trim(string: String) -> String {
        // trim string
        let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return trimmedString.stringByReplacingOccurrencesOfString("&", withString: "", options: .LiteralSearch, range: nil)
    }
    
    static func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    static func getValidStringValue(s: AnyObject?) -> String {
        if s != nil {
            if let string = s as? String {
                return string
            } else {
                return "\(s!)"
            }
        } else {
            return ""
        }
    }
    
    static func getValidIntValue(s: AnyObject?) -> Int {
        if s == nil {
            return 0
        }
        let intString = "\(s!)"
        let intValue = Int(intString)
        if intValue == nil {
            return 0
        }
        return intValue!
    }
    
    static func switchToLoginViewController() {
        // change rootViewController to loginViewController
        let storyboard = UIStoryboard(name: StoryboardNames.Account.rawValue, bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("accountNavigationViewController") 
        
        if UIApplication.sharedApplication().keyWindow != nil {
            UIApplication.sharedApplication().keyWindow!.rootViewController = rootViewController
        } else {
            UIApplication.sharedApplication().delegate?.window??.rootViewController = rootViewController
        }
    }
    
    static func clearLocalAndRemoteNotificationCount() {
        // clear push notification badge
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        // send request to server to clear number of push notification badges for this user
        Toolbox.asyncHttpPostToURL(URLClearNumberOfBadgesForPushNotification, parameters: "", delegate: nil)
    }
    
    static func isSystemVersionGreaterThanOrEqualTo(version: String) -> Bool {
        return UIDevice.currentDevice().systemVersion.compare(version, options: .NumericSearch) != NSComparisonResult.OrderedAscending
    }
    
    static func showAlertView(title: String) {
        let alertView = UIAlertView(title: title, message: title, delegate: nil, cancelButtonTitle: "确定")
        alertView.show()
    }
    
    static func removeSuffixOfProvinceAndCity(place: String) -> String {
        return place.stringByReplacingOccurrencesOfString("省", withString: "").stringByReplacingOccurrencesOfString("市", withString: "")
    }
    
    static func removeBottomShadowOfNavigationBar(navigationBar: UINavigationBar) {
        // the following 2 lines of code removes the bottom border of navigation bar
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(Toolbox.imageWithColor(ColorSettledGreen), forBarMetrics: .Default)
    }
    
    /**
    Navigation to view controller in a different storyboard
    
    - parameter currentNavigationController: current navigation controller
    - parameter storyboardIdentifier:        destination storyboard identifier
    - parameter destinationViewController:   destination view controller in the destination storyboard, when passed in as empty string, meaning that the destination view controller is the initial view controller of the destination storyboard
    */
    static func navigationToViewControllerInDifferentStoryboard(currentNavigationController: UINavigationController?, storyboardIdentifier: String, destinationViewControllerIdentifier: String?) {
        let destinationStoryboard = UIStoryboard(name: storyboardIdentifier, bundle: nil)
        if Toolbox.isStringValueValid(destinationViewControllerIdentifier) {
            let destinationVC = destinationStoryboard.instantiateViewControllerWithIdentifier(destinationViewControllerIdentifier!)
            currentNavigationController?.pushViewController(destinationVC, animated: true)
        } else {
            let destinationVC = destinationStoryboard.instantiateInitialViewController()
            currentNavigationController?.pushViewController(destinationVC!, animated: true)
        }
    }
    
    /**
    Set label color based on its number value
    
    - parameter label: the label that needs to change its text color
    */
    static func setLabelColorBasedOnAttributeValue(label: UILabel) {
        let labelTextValue = Float(label.text!)
        if labelTextValue == nil {
            return
        }
        if labelTextValue < 4.0 {
            label.backgroundColor = ColorOrange
        } else if labelTextValue < 7.0 {
            label.backgroundColor = ColorYellow
        } else {
            label.backgroundColor = ColorSolidGreen
        }
        label.textColor = UIColor.whiteColor()
    }
    
    /**
    remove the province name from the given location string
    
    - parameter location: location string such as "湖南长沙"
    */
    static func removeProvinceNameFromString(location: String) -> String {
        if location.containsString("河北") {
            return location.stringByReplacingOccurrencesOfString("河北", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("山西") {
            return location.stringByReplacingOccurrencesOfString("山西", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("辽宁") {
            return location.stringByReplacingOccurrencesOfString("辽宁", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("吉林") {
            return location.stringByReplacingOccurrencesOfString("吉林", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("黑龙江") {
            return location.stringByReplacingOccurrencesOfString("黑龙江", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("江苏") {
            return location.stringByReplacingOccurrencesOfString("江苏", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("浙江") {
            return location.stringByReplacingOccurrencesOfString("浙江", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("安徽") {
            return location.stringByReplacingOccurrencesOfString("安徽", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("福建") {
            return location.stringByReplacingOccurrencesOfString("福建", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("江西") {
            return location.stringByReplacingOccurrencesOfString("江西", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("山东") {
            return location.stringByReplacingOccurrencesOfString("山东", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("河南") {
            return location.stringByReplacingOccurrencesOfString("河南", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("湖北") {
            return location.stringByReplacingOccurrencesOfString("湖北", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("内蒙古") {
            return location.stringByReplacingOccurrencesOfString("内蒙古", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("宁夏") {
            return location.stringByReplacingOccurrencesOfString("宁夏", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("湖南") {
            return location.stringByReplacingOccurrencesOfString("湖南", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("广东") {
            return location.stringByReplacingOccurrencesOfString("广东", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("广西") {
            return location.stringByReplacingOccurrencesOfString("广西", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("海南") {
            return location.stringByReplacingOccurrencesOfString("海南", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("四川") {
            return location.stringByReplacingOccurrencesOfString("四川", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("贵州") {
            return location.stringByReplacingOccurrencesOfString("贵州", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("云南") {
            return location.stringByReplacingOccurrencesOfString("云南", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("陕西") {
            return location.stringByReplacingOccurrencesOfString("陕西", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("甘肃") {
            return location.stringByReplacingOccurrencesOfString("甘肃", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("西藏") {
            return location.stringByReplacingOccurrencesOfString("西藏", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("新疆") {
            return location.stringByReplacingOccurrencesOfString("新疆", withString: "", options: .LiteralSearch, range: nil)
        } else if location.containsString("青海") {
            return location.stringByReplacingOccurrencesOfString("青海", withString: "", options: .LiteralSearch, range: nil)
        }
        return location
    }
    
    static func setPaginatedTableFooterView(total: Int, numOfLoaded: Int, isLoadingNextPage: Bool, buttonTitle: String, buttonActionSelector: Selector, viewController: UIViewController) -> UIView {
        // no more models can be loaded
        if total == numOfLoaded {
            return UIView(frame: CGRectZero)
        }
        let footerView = UIView(frame: CGRectMake(0, 0, ScreenSize.width, TableSectionFooterHeightWithButton))
        if !isLoadingNextPage { // Not loading next page, should show next page button
            let nextPageButton = Appearance.setupTableFooterButtonWithTitle(buttonTitle, backgroundColor: ColorSettledGreen)
            nextPageButton.addTarget(viewController, action: buttonActionSelector, forControlEvents: .TouchUpInside)
            footerView.addSubview(nextPageButton)
        } else {    // currently loading next page, should show activity indicator
            // Create and add the activityIndicator to footerView to indicate currentyl loading next page
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
            activityIndicator.alpha = 1.0
            activityIndicator.color = UIColor.blackColor()
            activityIndicator.center = CGPointMake(ScreenSize.width / 2, TableSectionFooterHeightWithButton / 2)
            activityIndicator.hidesWhenStopped = false
            footerView.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
        return footerView
    }
    
}
