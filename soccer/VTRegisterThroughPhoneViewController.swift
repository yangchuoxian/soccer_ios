//
//  VTRegisterThroughPhoneViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/19.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTRegisterThroughPhoneViewController: UIViewController, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, NSURLConnectionDataDelegate, NSURLConnectionDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var input_phone: UITextField!
    @IBOutlet weak var input_password: UITextField!
    @IBOutlet weak var input_verificationCode: UITextField!
    @IBOutlet weak var button_register: UIButton!
    @IBOutlet weak var image_avatar: UIImageView!
    @IBOutlet weak var button_getVerificationCode: UIButton!
    
    enum httpRequest {
        case UploadAvatar
        case GetVerificationCode
        case SubmitNewUser
    }
    
    var picker: UIImagePickerController?
    var HUD: MBProgressHUD?
    var userId: String?
    var currentActiveTextFieldIndex: Int?
    var indexOfCurrentHttpRequest: httpRequest?
    var responseData: NSMutableData? = NSMutableData()
    var countdownTimer: NSTimer?
    var secondsBeforeResendingSMS: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeAvatarImage(self.image_avatar)
        Appearance.customizeTextField(self.input_phone, iconName: "phone")
        Appearance.customizeTextField(self.input_password, iconName: "locked")
        Appearance.customizeTextField(self.input_verificationCode, iconName: "key2")
        
        self.button_register.layer.cornerRadius = 2.0
        // add tap gesture event to image_avatar, when image_avatar is tapped, user will be provided with options to whether select image or shoot a photo as avatar to upload
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "avatarImageTapped")
        singleTap.numberOfTapsRequired = 1
        
        self.image_avatar.userInteractionEnabled = true
        self.image_avatar.addGestureRecognizer(singleTap)
        // assign tag value for different textField so that the system knows which textField is active/being edited
        self.input_phone.tag = 1
        self.input_password.tag = 2
        self.input_verificationCode.tag = 3
        
        self.input_phone.delegate = self
        self.input_password.delegate = self
        self.input_verificationCode.delegate = self
        
        // add tap gesture for scrollView to hide keyboard
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideKeyboard:")
        self.scrollView.addGestureRecognizer(gestureRecognizer)
        self.input_phone.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
        self.input_password.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
        self.input_verificationCode.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        // release the timer
        if self.countdownTimer != nil {
            self.countdownTimer?.invalidate()
            self.countdownTimer = nil
        }
    }
    
    func validateUserInput() {
        let enteredPhoneNumber = Toolbox.trim(self.input_phone.text!)
        let enteredPasswordLength = Toolbox.trim(self.input_password.text!).characters.count
        let enteredVerificationCode = Toolbox.trim(self.input_verificationCode.text!)
        
        if enteredPhoneNumber.characters.count == 11 && self.countdownTimer == nil {
            self.button_getVerificationCode.enabled = true
            self.button_getVerificationCode.setTitleColor(ColorDefaultBlue, forState: .Normal)
        } else {
            self.button_getVerificationCode.enabled = false
            self.button_getVerificationCode.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        }
        
        if enteredPhoneNumber.characters.count == 11 &&
            enteredPasswordLength >= 6 && enteredPasswordLength <= 20 &&
            enteredVerificationCode.characters.count == 6 {
            Toolbox.toggleButton(self.button_register, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_register, enabled: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func hideKeyboard(sender: AnyObject) {
        // hide keyboard
        self.input_phone.resignFirstResponder()
        self.input_password.resignFirstResponder()
        self.input_verificationCode.resignFirstResponder()
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {   // choose image from gallery
            // release self.picker memory first
            if self.picker != nil {
                self.picker?.delegate = nil
            }
            self.picker = nil
            
            self.picker = UIImagePickerController()
            self.picker?.delegate = self
            self.picker?.allowsEditing = true
            self.picker?.sourceType = .PhotoLibrary
            
            self.presentViewController(self.picker!, animated: true, completion: nil)
        } else if buttonIndex == 2 {    // take a photo
            if self.picker != nil {
                self.picker?.delegate = nil
            }
            self.picker = nil
            
            self.picker = UIImagePickerController()
            self.picker?.delegate = self
            self.picker?.allowsEditing = true
            self.picker?.sourceType = .Camera
            
            self.presentViewController(self.picker!, animated: true, completion: nil)
        }
    }

    func avatarImageTapped() {
        let selectPhoto: String = "选择照片"
        let takePhoto: String = "拍照"
        let cancelTitle: String = "取消"
        let actionSheet: UIActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: cancelTitle, destructiveButtonTitle: nil, otherButtonTitles: selectPhoto, takePhoto)
        actionSheet.showInView(self.view)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.currentActiveTextFieldIndex = textField.tag
    }
    
    // called when the UIKeyboardDidShowNotification is sent
    func keyboardWasShown(notification: NSNotification) {
        let info: NSDictionary = notification.userInfo!
        let keyboardSize: CGSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        // if active text field is hidden by keyboard, scroll it so it's visible
        let tempRect: CGRect = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y + (ToolbarHeight + NavigationbarHeight), width: self.view.frame.size.width, height: self.view.frame.size.height - keyboardSize.height - (ToolbarHeight + NavigationbarHeight))
        var activeField: UITextField?
        switch self.currentActiveTextFieldIndex! {
        case 1:
            activeField = self.input_phone
            break
        case 2:
            activeField = self.input_password
            break
        case 3:
            activeField = self.input_verificationCode
            break
        default:
            activeField = nil
            break
        }
        if !CGRectContainsPoint(tempRect, activeField!.frame.origin) {
            self.scrollView.scrollRectToVisible(activeField!.frame, animated: true)
        }
    }
    
    // called when the UIKeyboardWillHideNotification is sent
    func keyboardWillBeHidden(notification: NSNotification) {
        let contentInsets = UIEdgeInsets(top: ToolbarHeight + NavigationbarHeight, left: 0, bottom: 0, right: 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.input_phone {
            self.input_phone.resignFirstResponder()
            self.input_verificationCode.becomeFirstResponder()
            return true
        } else if textField == self.input_verificationCode {
            self.input_verificationCode.resignFirstResponder()
            self.input_password.becomeFirstResponder()
            return true
        } else if textField == self.input_password {
            if self.button_register.enabled {
                self.input_password.resignFirstResponder()
                self.button_register.sendActionsForControlEvents(.TouchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        Appearance.customizeNavigationBar(self, title: "用户注册")
        // register for keyboard notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.image_avatar.image = image
        self.uploadAvatar(image)
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        if self.picker != nil {
            self.picker?.delegate = nil
        }
        self.picker = nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "serviceAgreementSegue" {
            let destinationViewController = segue.destinationViewController as! VTPostViewController
            destinationViewController.postType = .ServiceAgreement
        }
    }
    
    func uploadAvatar(image: UIImage) {
        var connection: NSURLConnection?
        if Toolbox.isStringValueValid(self.userId) {    // self.userId defined, meaning user avatar is already uploaded, temporary user already generated in server database
            let postParamsDictionary = ["modelId": self.userId!]
            connection = Toolbox.uploadImageToURL(URLUploadUserAvatar, image: image, parameters: postParamsDictionary, delegate: self)
        } else {
            connection = Toolbox.uploadImageToURL(URLUploadUserAvatar, image: image, parameters: nil, delegate: self)
        }
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .UploadAvatar
            self.HUD = MBProgressHUD(view: self.navigationController?.view)
            self.navigationController?.view.addSubview(self.HUD!)
            self.HUD?.show(true)
        }
        connection = nil
    }
    
    @IBAction func sendVerificationCode(sender: AnyObject) {
        let phone = Toolbox.trim(self.input_phone.text!)
        let connection = Toolbox.asyncHttpGetFromURL(URLGetVerificationCode + "?phone=\(phone)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .GetVerificationCode
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    @IBAction func submitRegistration(sender: AnyObject) {
        let phone = Toolbox.trim(self.input_phone.text!)
        let password = Toolbox.trim(self.input_password.text!)
        let verificationCode = Toolbox.trim(self.input_verificationCode.text!)
        
        var postParamsString: String
        if Toolbox.isStringValueValid(self.userId) {
            postParamsString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("phone=\(phone)&password=\(password)&verificationCode=\(verificationCode)&id=\(self.userId!)")
        } else {    // self.userId not defined, meaning user avatar is NOT uploaded
            postParamsString = Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("phone=\(phone)&password=\(password)&verificationCode=\(verificationCode)")
        }
        let connection = Toolbox.asyncHttpPostToURL(URLSubmitNewUser, parameters: postParamsString, delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.indexOfCurrentHttpRequest = .SubmitNewUser
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD!.hide(true)
        self.HUD = nil
        
        let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
        if self.indexOfCurrentHttpRequest == .UploadAvatar {    // upload avatar http request
            // retrieve user id from json data
            let jsonArray = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            self.userId = jsonArray!["modelId"] as? String
            Toolbox.saveAvatarImageLocally(self.image_avatar.image!, modelId: self.userId!)
        } else if self.indexOfCurrentHttpRequest == .GetVerificationCode {  // asks server to send verification code to cell phone
            if responseStr == "OK" {    // send verification succeeded
                // disable button to send SMS, in the mean while, set up a timer so that user can only tap the button to send SMS again after 1 minutes
                self.button_getVerificationCode.enabled = false
                self.button_getVerificationCode.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
                self.secondsBeforeResendingSMS = 60
                self.button_getVerificationCode.setTitle("验证码已发送(\(self.secondsBeforeResendingSMS!))", forState: .Normal)
                self.countdownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "resendSMSCountdown", userInfo: nil, repeats: true)
            } else {    // send verification failed with error message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
        } else {    // submit new user http request
            // if registration succeeded, response from server should be user info JSON data, so retrieve username from this JSON data to see if registration is successful
            let userJSON = (try? NSJSONSerialization.JSONObjectWithData(self.responseData!, options: .MutableLeaves)) as? [NSObject: AnyObject]
            
            let respondedUsername = userJSON?["username"] as? String
            if respondedUsername != nil {   // submit new user succeeded
                Singleton_CurrentUser.sharedInstance.processUserLogin(userJSON!)
            } else {    // submit new user failed with error message
                Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
            }
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func resendSMSCountdown() {
        self.secondsBeforeResendingSMS = self.secondsBeforeResendingSMS! - 1
        if self.secondsBeforeResendingSMS == 0 {    // time off, should enable button to send SMS to allow resend
            self.button_getVerificationCode.enabled = true
            self.button_getVerificationCode.setTitleColor(ColorDefaultBlue, forState: .Normal)
            self.button_getVerificationCode.setTitle("获取验证码", forState: .Normal)
            // release timer
            self.countdownTimer?.invalidate()
            self.countdownTimer = nil
        } else {
            self.button_getVerificationCode.setTitle("验证码已发送(\(self.secondsBeforeResendingSMS!))", forState: .Normal)
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD!.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "加载失败")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.image_avatar.image = nil
        if self.picker != nil {
            self.picker?.delegate = nil
            self.picker = nil
        }
        self.HUD = nil
        self.userId = nil
        self.currentActiveTextFieldIndex = nil
        self.indexOfCurrentHttpRequest = nil
        self.responseData = nil
    }
    
}
