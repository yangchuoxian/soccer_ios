//
//  VTLoginViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/28.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

@objc class VTLoginViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate, UIActionSheetDelegate {
    
    @IBOutlet weak var input_username: UITextField!
    @IBOutlet weak var input_password: UITextField!
    @IBOutlet weak var button_login: UIButton!
    @IBOutlet weak var imageView_appIconOrLastLoginUserAvatar: UIImageView!
    
    enum ActionSheetID {
        case retrievePasswordOptions
        case registerOptions
    }
    
    var HUD: MBProgressHUD?
    var username: String?
    var responseData: NSMutableData? = NSMutableData()
    var verificationType: VerificationCodeType?
    var currentActiveActionSheet: ActionSheetID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Appearance.customizeTextField(self.input_username, iconName: "person")
        Appearance.customizeTextField(self.input_password, iconName: "locked")
        
        self.button_login.layer.cornerRadius = 2.0
        // round corner for app icon image view
        self.imageView_appIconOrLastLoginUserAvatar.layer.cornerRadius = 20.0
        self.imageView_appIconOrLastLoginUserAvatar.clipsToBounds = true
        let lastLoginUserId = NSUserDefaults.standardUserDefaults().stringForKey("lastLoginUserId")
        if Toolbox.isStringValueValid(lastLoginUserId) {
            Toolbox.loadAvatarImage(lastLoginUserId!, toImageView: self.imageView_appIconOrLastLoginUserAvatar, avatarType: AvatarType.User)
        }
        
        self.input_username.delegate = self
        self.input_password.delegate = self
        self.input_username.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
        self.input_password.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    func validateUserInput() {
        let enteredUsernameLength = Toolbox.trim(self.input_username.text!).characters.count
        let enteredPasswordLength = Toolbox.trim(self.input_password.text!).characters.count
        if enteredUsernameLength > 0 && enteredUsernameLength <= 80 && enteredPasswordLength >= 6 && enteredPasswordLength <= 20 {
            Toolbox.toggleButton(self.button_login, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_login, enabled: false)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard iteslf
        self.input_username.resignFirstResponder()
        self.input_password.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.input_username {
            self.input_username.resignFirstResponder()
            self.input_password.becomeFirstResponder()
            return true
        } else if textField == self.input_password {
            if self.button_login.enabled {
                self.input_password.resignFirstResponder()
                self.button_login.sendActionsForControlEvents(.TouchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    @IBAction func showResetPasswordOptions(sender: AnyObject) {
        let sendSMS = "发送短信验证码"
        let sendEmail = "发送邮件验证码"
        let cancelTitle: String = "取消"
        let actionSheet: UIActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelTitle, destructiveButtonTitle: nil, otherButtonTitles: sendSMS, sendEmail)
        actionSheet.showInView(self.view)
        self.currentActiveActionSheet = .retrievePasswordOptions
    }
    
    @IBAction func showRegisterOptions(sender: AnyObject) {
        let registerThroughEmail = "通过邮箱注册"
        let registerThroughPhone = "通过手机号注册"
        let cancelTitle = "取消"
        let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelTitle, destructiveButtonTitle: nil, otherButtonTitles: registerThroughPhone, registerThroughEmail)
        actionSheet.showInView(self.view)
        self.currentActiveActionSheet = .registerOptions
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if self.currentActiveActionSheet == .retrievePasswordOptions {
            if buttonIndex == 1 {   // user chose to retrieve password by SMS
                self.verificationType = .SMS
            } else if buttonIndex == 2 {    // user chose to retrieve password by email
                self.verificationType = .Email
            } else {    // cancel button clicked
                return
            }
            self.performSegueWithIdentifier("sendVerificationCodeSegue", sender: self)
        } else {
            if buttonIndex == 1 {   // user chose to register through phone
                self.performSegueWithIdentifier("registerThroughPhoneSegue", sender: self)
            } else if buttonIndex == 2 {    // user chose to register through email
                self.performSegueWithIdentifier("registerThroughEmailSegue", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "sendVerificationCodeSegue" {
            let destinationNavigationController = segue.destinationViewController as! UINavigationController
            let enterUserIdentityForVerificationViewController = destinationNavigationController.viewControllers[0] as! VTEnterUserIdentityForVerificationViewController
            enterUserIdentityForVerificationViewController.verificationType = self.verificationType
        }
    }
    
    @IBAction func submitLogin(sender: AnyObject) {
        let username = Toolbox.trim(self.input_username.text!)
        let password = Toolbox.trim(self.input_password.text!)
        // save login username
        self.username = username
        let connection = Toolbox.asyncHttpPostToURL(
            URLSubmitLogin,
            parameters: Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("username=\(username)&password=\(password)"),
            delegate: self
        )
        if connection == nil {
            // inform the user that the connection failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        // if login succeeded, response from server should be user info JSON data, so retrieve username from this JSON data to see if login is successful
        let userJSON = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
        if userJSON != nil {   // login succeeded
            Singleton_CurrentUser.sharedInstance.processUserLogin(userJSON!)
        } else {    // login failed with error message
            let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr! as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    @IBAction func unwindToLoginView(segue: UIStoryboardSegue) {
    }
    
    deinit {
        self.HUD = nil
        self.username = nil
        self.responseData = nil
        self.verificationType = nil
        self.currentActiveActionSheet = nil
    }
    
}
