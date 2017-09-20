//
//  ToolBox.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/4.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class Toolbox: NSObject, MBProgressHUDDelegate {
    
    static func isStringValueValid(_ value: String?) -> Bool {
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
    static func isDateStringServerDateFormat(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSz"
        let dateTimeString = dateFormatter.date(from: dateString)
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
    static func formatTimeString(_ timeString: String, shouldGetHourAndMinute getHourAndMinute: Bool) -> String {
        if !Toolbox.isDateStringServerDateFormat(timeString) {
            return timeString
        }
        let date = Date(dateTimeString: timeString)
        // get today's date
        let todayDate = Date()
        if date.isTheSameDayAs(todayDate) && getHourAndMinute {
            return date.getTimeString()
        } else {
            return date.getDateString()
        }
    }
    
    static func showCustomAlertViewWithImage(_ imageName: String, title t: String) {
        var HUD = MBProgressHUD(view: Toolbox.getCurrentViewController()?.view)
        Toolbox.getCurrentViewController()?.view.addSubview(HUD!)
        HUD?.customView = UIImageView(image: UIImage(named: imageName))
        // Set custom view mode
        HUD?.mode = .customView
        HUD?.labelText = t
        HUD?.show(true)
        // hide and remove HUD view a while after
        HUD?.hide(true, afterDelay: 1)
        HUD = nil
    }
    
    static func setupCustomProcessingViewWithTitle(title t: String?) -> MBProgressHUD {
        let HUD = MBProgressHUD(view: Toolbox.getCurrentViewController()?.view)
        if Toolbox.isStringValueValid(t) {
            HUD?.labelText = t
        }
        Toolbox.getCurrentViewController()?.view.addSubview(HUD!)
        HUD?.show(true)
        return HUD!
    }
    
    /**
     * For http requests sent from mobile native app, the server validates whether
     * the request is sent by logged in user by checking the login token and user id,
     * if it matches, the request can go through, otherwise, it is an illegal request
     */
    static func addLoginTokenAndCurrentUserIdToHttpRequestParameters(_ urlOrPostParameters: String) -> String {
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
    static func addDeviceIDAndDeviceTypeToHttpRequestParameters(_ urlOrPostParameters: String) -> String {
        let deviceTokenString = UserDefaults.standard.string(forKey: "deviceToken")
        if Toolbox.isStringValueValid(deviceTokenString) {
            return urlOrPostParameters + "&deviceID=\(deviceTokenString!)&deviceType=\(DeviceType.ios.rawValue)"
        } else {
            return urlOrPostParameters
        }
    }
    
    /* ASYNCHRONOUS http get request */
    static func asyncHttpGetFromURL(_ url: String, delegate d: AnyObject) -> NSURLConnection? {
        let completeUrl = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(url)
        let url_encoded = completeUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)

        let request = NSMutableURLRequest(url: URL(string: url_encoded!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TimeIntervals.httpRequestTimeout.rawValue)
        request.httpMethod = "GET"
        return NSURLConnection(request: request, delegate: d)
    }
    
    /* ASYNCHRONOUS http post request */
    static func asyncHttpPostToURL(_ url: String, parameters postParametersString: String, delegate d: AnyObject?) -> NSURLConnection? {
        let completePostParamsString = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(postParametersString)
        let postParametersStringThatEscapedSpecialCharacters = completePostParamsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        // set post parameters
        let postParametersData = postParametersStringThatEscapedSpecialCharacters!.data(using: String.Encoding.utf8, allowLossyConversion: true)
        let postParametersLength = "\((postParametersStringThatEscapedSpecialCharacters!).characters.count)"
        // http request to get service agreement content from server
        let url_encoded = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let request = NSMutableURLRequest(url: URL(string: url_encoded!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TimeIntervals.httpRequestTimeout.rawValue)
        request.httpMethod = "POST"
        request.setValue(postParametersLength, forHTTPHeaderField: "Content-Length")
        request.httpBody = postParametersData
        
        // start asynchronous http request
        return NSURLConnection(request: request, delegate: d)
    }
    
    /* SYNCHRONOUS http get request */
    static func syncHttpGetFromURL(_ url: String) -> Data? {
        let completeUrl = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(url)
        let url_encoded = completeUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let request = NSMutableURLRequest(url: URL(string: url_encoded!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TimeIntervals.httpRequestTimeout.rawValue)
        request.httpMethod = "GET"
        var response: URLResponse?
        var error: NSError?
        let responseData: Data?
        do {
            responseData = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
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
    static func syncHttpPost(_ url: String, parameters postParametersString: String) -> Data? {
        let completePostParamsString = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(postParametersString)
        let postParametersStringThatEscapedSpecialCharacters = completePostParamsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let postParametersData = postParametersStringThatEscapedSpecialCharacters!.data(using: String.Encoding.ascii, allowLossyConversion: true)
        let postParametersLength = "\(completePostParamsString.characters.count)"
        // http request to get service agreement content from server
        let url_encoded = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let request = NSMutableURLRequest(url: URL(string: url_encoded!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TimeIntervals.httpRequestTimeout.rawValue)
        request.httpMethod = "POST"
        request.setValue(postParametersLength, forHTTPHeaderField: "Content-Length")
        request.httpBody = postParametersData
        
        var response: URLResponse?
        var error: NSError?
        let responseData: Data?
        do {
            responseData = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
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
    static func asyncDownloadAvatarImageForModelId(_ modelId: String, avatarType aType: AvatarType, completionBlock: ((Bool, UIImage?) -> Void)?) {
        var urlWithParams: String
        if aType == .user {   // the avatar is for user
            urlWithParams = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(URLUserAvatar + modelId)
        } else {                                // the avatar is for team
            urlWithParams = Toolbox.addLoginTokenAndCurrentUserIdToHttpRequestParameters(URLTeamAvatar + modelId)
        }
        let request = NSMutableURLRequest(url: URL(string: urlWithParams)!)
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main, completionHandler: {
            response, data, error in
            let httpResponse = response as? HTTPURLResponse
            if httpResponse != nil {
                if httpResponse?.statusCode == HttpStatusCode.ok.rawValue {  // avatar download succeeded
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
    
    static func uploadImageToURL(_ url: String, image i: UIImage, parameters pDictionary: [AnyHashable: Any]?, delegate d: AnyObject) -> NSURLConnection? {
        let httpDataBoundary = "---------------------------14737809831466499882746641449"

        let imageData = UIImageJPEGRepresentation(i, 1.0)
        let imageExtension = ".jpg"
        let contentType = "multipart/form-data; boundary=\(httpDataBoundary)"
        
        let body = NSMutableData()
        if pDictionary != nil {
            for (name, value) in pDictionary! {
                body.append("--\(httpDataBoundary)\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append("\(value)\r\n\r\n".data(using: String.Encoding.utf8)!)
            }
        }
        
        // get login token and currentUserId from userDefaults
        let credentialInfo = Toolbox.getUserCredential()
        if credentialInfo != nil {
            for (name, value) in credentialInfo! {
                body.append("--\(httpDataBoundary)\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append("\(value)\r\n\r\n".data(using: String.Encoding.utf8)!)
            }
        }
        
        body.append("\r\n--\(httpDataBoundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"user_avatar\(imageExtension)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: String.Encoding.utf8)!)
        
        body.append(NSData(data: imageData!) as Data)
        body.append("\r\n--\(httpDataBoundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        let url_encoded = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let request = NSMutableURLRequest(url: URL(string: url_encoded!)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: TimeIntervals.imageUploadTimeout.rawValue)
        request.httpMethod = "POST"
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        // set the content-length
        let postLength = "\(body.length)"
        
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.httpBody = body
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
    static func loadAvatarImage(_ modelId: String, toImageView imageView: UIImageView, avatarType aType: AvatarType) {
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
    static func getAvatarImagePathForModelId(_ modelId: String) -> String? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        let avatarFilePath = "\(documentsPath)/\(modelId).png"
        let avatarFileExists = FileManager.default.fileExists(atPath: avatarFilePath)
        if avatarFileExists {
            return avatarFilePath
        } else {
            return nil
        }
    }
    
    static func saveAvatarImageLocally(_ avatarImage: UIImage, modelId mId: String) -> Bool {
        let imageData = UIImagePNGRepresentation(avatarImage)
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let imagePath = "\(documentsDirectory)/\(mId).png"
        
        return ((try? imageData!.write(to: URL(fileURLWithPath: imagePath), options: [])) != nil)
    }
    
    /**
     * With dictionary or array data structure, this function converts it to JSON string as http post parameters
     */
    static func convertDictionaryOrArrayToJSONString(_ arrayOrDictionary: AnyObject) -> String {
        let JSONData: Data?
        do {
            JSONData = try JSONSerialization.data(withJSONObject: arrayOrDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            JSONData = nil
        }
        let JSONString = NSString(data: JSONData!, encoding: String.Encoding.utf8.rawValue)
        return JSONString as! String
    }
    
    /**
     * Function to store username and password in keychain
     */
    static func saveUserCredential(_ currentUserId: String, loginToken token: String) {
        // store username and password in keychain
        var keychainItem = KeychainItemWrapper(identifier: "SoccerAppLogin", accessGroup: nil)
        keychainItem?.setObject(currentUserId, forKey: kSecAttrAccount)
        keychainItem?.setObject(token, forKey: kSecValueData)
        keychainItem = nil
    }
    
    /**
     * Retrieve login credentials saved in keychain
     */
    static func getUserCredential() -> [String: String]? {
        let keychainItem = KeychainItemWrapper(identifier: "SoccerAppLogin", accessGroup: nil)
        let currentUserId = keychainItem?.object(forKey: kSecAttrAccount) as? String
        let loginTokenData = keychainItem?.object(forKey: kSecValueData) as? Data
        var loginToken: NSString?
        if Toolbox.isStringValueValid(currentUserId) && loginTokenData != nil {
            loginToken = NSString(data: loginTokenData!, encoding: String.Encoding.utf8.rawValue)
            return [
                "currentUserId": currentUserId!,
                "loginToken": loginToken as! String
            ]
        } else {
            return nil
        }
    }
    
    /* Create an image with given color */
    static func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    static func generateQRCodeWithString(_ string: String, scale s: CGFloat) -> UIImage? {
        let stringData = string.data(using: String.Encoding.utf8)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter!.setValue(stringData, forKey: "inputMessage")
        filter!.setValue("M", forKey: "inputCorrectionLevel")
        
        // Render the image into a CoreGraphics image
        let cgImage = CIContext(options: nil).createCGImage(filter!.outputImage!, from: filter!.outputImage!.extent)
        
        //Scale the image usign CoreGraphics
        UIGraphicsBeginImageContext(CGSize(width: filter!.outputImage!.extent.size.width * s, height: filter!.outputImage!.extent.size.width * s))
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = CGInterpolationQuality.none
        context?.draw(cgImage!, in: (context?.boundingBoxOfClipPath)!)
        let preImage = UIGraphicsGetImageFromCurrentImageContext()
        //Cleaning up
        UIGraphicsEndImageContext()
        // Rotate the image
        return UIImage(cgImage: (preImage?.cgImage!)!, scale: (preImage?.scale)!, orientation: .downMirrored)
    }
    
    /**
     * Get the topmost current showing view controller
     */
    static func getCurrentViewController() -> UIViewController? {
        // get current view controller
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            // topController should now be your topmost view controller
            return topController
        }
        return UIApplication.shared.delegate?.window??.rootViewController
    }
    
    static func toggleButton(_ button: UIButton, enabled e: Bool) {
        button.isEnabled = e
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
    static func trim(_ string: String) -> String {
        // trim string
        let trimmedString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmedString.replacingOccurrences(of: "&", with: "", options: .literal, range: nil)
    }
    
    static func isValidEmail(_ testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    static func getValidStringValue(_ s: AnyObject?) -> String {
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
    
    static func getValidIntValue(_ s: AnyObject?) -> Int {
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
        let rootViewController = storyboard.instantiateViewController(withIdentifier: "accountNavigationViewController") 
        
        if UIApplication.shared.keyWindow != nil {
            UIApplication.shared.keyWindow!.rootViewController = rootViewController
        } else {
            UIApplication.shared.delegate?.window??.rootViewController = rootViewController
        }
    }
    
    static func clearLocalAndRemoteNotificationCount() {
        // clear push notification badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        // send request to server to clear number of push notification badges for this user
        Toolbox.asyncHttpPostToURL(URLClearNumberOfBadgesForPushNotification, parameters: "", delegate: nil)
    }
    
    static func isSystemVersionGreaterThanOrEqualTo(_ version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version, options: .numeric) != ComparisonResult.orderedAscending
    }
    
    static func showAlertView(_ title: String) {
        let alertView = UIAlertView(title: title, message: title, delegate: nil, cancelButtonTitle: "确定")
        alertView.show()
    }
    
    static func removeSuffixOfProvinceAndCity(_ place: String) -> String {
        return place.replacingOccurrences(of: "省", with: "").replacingOccurrences(of: "市", with: "")
    }
    
    static func removeBottomShadowOfNavigationBar(_ navigationBar: UINavigationBar) {
        // the following 2 lines of code removes the bottom border of navigation bar
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(Toolbox.imageWithColor(ColorSettledGreen), for: .default)
    }
    
    /**
    Navigation to view controller in a different storyboard
    
    - parameter currentNavigationController: current navigation controller
    - parameter storyboardIdentifier:        destination storyboard identifier
    - parameter destinationViewController:   destination view controller in the destination storyboard, when passed in as empty string, meaning that the destination view controller is the initial view controller of the destination storyboard
    */
    static func navigationToViewControllerInDifferentStoryboard(_ currentNavigationController: UINavigationController?, storyboardIdentifier: String, destinationViewControllerIdentifier: String?) {
        let destinationStoryboard = UIStoryboard(name: storyboardIdentifier, bundle: nil)
        if Toolbox.isStringValueValid(destinationViewControllerIdentifier) {
            let destinationVC = destinationStoryboard.instantiateViewController(withIdentifier: destinationViewControllerIdentifier!)
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
    static func setLabelColorBasedOnAttributeValue(_ label: UILabel) {
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
        label.textColor = UIColor.white
    }
    
    /**
    remove the province name from the given location string
    
    - parameter location: location string such as "湖南长沙"
    */
    static func removeProvinceNameFromString(_ location: String) -> String {
        if location.contains("河北") {
            return location.replacingOccurrences(of: "河北", with: "", options: .literal, range: nil)
        } else if location.contains("山西") {
            return location.replacingOccurrences(of: "山西", with: "", options: .literal, range: nil)
        } else if location.contains("辽宁") {
            return location.replacingOccurrences(of: "辽宁", with: "", options: .literal, range: nil)
        } else if location.contains("吉林") {
            return location.replacingOccurrences(of: "吉林", with: "", options: .literal, range: nil)
        } else if location.contains("黑龙江") {
            return location.replacingOccurrences(of: "黑龙江", with: "", options: .literal, range: nil)
        } else if location.contains("江苏") {
            return location.replacingOccurrences(of: "江苏", with: "", options: .literal, range: nil)
        } else if location.contains("浙江") {
            return location.replacingOccurrences(of: "浙江", with: "", options: .literal, range: nil)
        } else if location.contains("安徽") {
            return location.replacingOccurrences(of: "安徽", with: "", options: .literal, range: nil)
        } else if location.contains("福建") {
            return location.replacingOccurrences(of: "福建", with: "", options: .literal, range: nil)
        } else if location.contains("江西") {
            return location.replacingOccurrences(of: "江西", with: "", options: .literal, range: nil)
        } else if location.contains("山东") {
            return location.replacingOccurrences(of: "山东", with: "", options: .literal, range: nil)
        } else if location.contains("河南") {
            return location.replacingOccurrences(of: "河南", with: "", options: .literal, range: nil)
        } else if location.contains("湖北") {
            return location.replacingOccurrences(of: "湖北", with: "", options: .literal, range: nil)
        } else if location.contains("内蒙古") {
            return location.replacingOccurrences(of: "内蒙古", with: "", options: .literal, range: nil)
        } else if location.contains("宁夏") {
            return location.replacingOccurrences(of: "宁夏", with: "", options: .literal, range: nil)
        } else if location.contains("湖南") {
            return location.replacingOccurrences(of: "湖南", with: "", options: .literal, range: nil)
        } else if location.contains("广东") {
            return location.replacingOccurrences(of: "广东", with: "", options: .literal, range: nil)
        } else if location.contains("广西") {
            return location.replacingOccurrences(of: "广西", with: "", options: .literal, range: nil)
        } else if location.contains("海南") {
            return location.replacingOccurrences(of: "海南", with: "", options: .literal, range: nil)
        } else if location.contains("四川") {
            return location.replacingOccurrences(of: "四川", with: "", options: .literal, range: nil)
        } else if location.contains("贵州") {
            return location.replacingOccurrences(of: "贵州", with: "", options: .literal, range: nil)
        } else if location.contains("云南") {
            return location.replacingOccurrences(of: "云南", with: "", options: .literal, range: nil)
        } else if location.contains("陕西") {
            return location.replacingOccurrences(of: "陕西", with: "", options: .literal, range: nil)
        } else if location.contains("甘肃") {
            return location.replacingOccurrences(of: "甘肃", with: "", options: .literal, range: nil)
        } else if location.contains("西藏") {
            return location.replacingOccurrences(of: "西藏", with: "", options: .literal, range: nil)
        } else if location.contains("新疆") {
            return location.replacingOccurrences(of: "新疆", with: "", options: .literal, range: nil)
        } else if location.contains("青海") {
            return location.replacingOccurrences(of: "青海", with: "", options: .literal, range: nil)
        }
        return location
    }
    
    static func setPaginatedTableFooterView(_ total: Int, numOfLoaded: Int, isLoadingNextPage: Bool, buttonTitle: String, buttonActionSelector: Selector, viewController: UIViewController) -> UIView {
        // no more models can be loaded
        if total == numOfLoaded {
            return UIView(frame: CGRect.zero)
        }
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSize.width, height: TableSectionFooterHeightWithButton))
        if !isLoadingNextPage { // Not loading next page, should show next page button
            let nextPageButton = Appearance.setupTableFooterButtonWithTitle(buttonTitle, backgroundColor: ColorSettledGreen)
            nextPageButton.addTarget(viewController, action: buttonActionSelector, for: .touchUpInside)
            footerView.addSubview(nextPageButton)
        } else {    // currently loading next page, should show activity indicator
            // Create and add the activityIndicator to footerView to indicate currentyl loading next page
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            activityIndicator.alpha = 1.0
            activityIndicator.color = UIColor.black
            activityIndicator.center = CGPoint(x: ScreenSize.width / 2, y: TableSectionFooterHeightWithButton / 2)
            activityIndicator.hidesWhenStopped = false
            footerView.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
        return footerView
    }
    
}
