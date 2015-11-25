//
//  VTEnterVerificationCodeViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/8.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTEnterVerificationCodeViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    @IBOutlet weak var label_verificationHasBeenSentTo: UILabel!
    @IBOutlet weak var label_phoneNumberOrEmailAddress: UILabel!
    @IBOutlet weak var input_verificationCode: UITextField!
    @IBOutlet weak var button_submitVerificationCode: UIButton!
    
    var verificationType: VerificationCodeType?
    var HUD: MBProgressHUD?
    var destinedPhoneNumberOrEmailAddress = ""
    var userId = ""
    var verificationCode = ""
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_verificationCode, iconName: "locked")
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target:self, action: "cancelResettingPassword")
        // empty bar back button text
        self.navigationController!.navigationBar.topItem!.title = ""
        if self.verificationType == .Email {
            self.label_verificationHasBeenSentTo.text = "验证码已发送至邮箱地址："
        } else {
            self.label_verificationHasBeenSentTo.text = "验证码已发送至手机号："
        }
        self.label_phoneNumberOrEmailAddress.text = self.destinedPhoneNumberOrEmailAddress
        self.input_verificationCode.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    func cancelResettingPassword() {
        // unwind back to login view controller
        self.performSegueWithIdentifier("unwindFromEnterVerificationCodeToLoginView", sender: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "输入验证码")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_verificationCode.resignFirstResponder()
    }
    
    func validateUserInput() {
        if Toolbox.trim(self.input_verificationCode.text!).characters.count == 6 {
            Toolbox.toggleButton(self.button_submitVerificationCode, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submitVerificationCode, enabled: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func submitVerificationCode(sender: AnyObject) {
        let enteredVerificationCode = Toolbox.trim(self.input_verificationCode.text!)
        let connection = Toolbox.asyncHttpPostToURL(URLSubmitVerificationCode, parameters: "verificationCode=\(enteredVerificationCode)&userId=\(self.userId)", delegate: self)
        if connection == nil {
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
        
        let responseStr = NSString(data: self.responseData!, encoding: NSUTF8StringEncoding)
        if responseStr == "OK" {    // verification code validation succeeded
            self.verificationCode = self.input_verificationCode.text!
            self.performSegueWithIdentifier("resetPasswordSegue", sender: self)
        } else {    // verification code validation failed
            self.input_verificationCode.text = nil
            Toolbox.toggleButton(self.button_submitVerificationCode, enabled: false)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "resetPasswordSegue" {
            let destinationViewController = segue.destinationViewController as! VTEnterNewPasswordViewController
            destinationViewController.userId = self.userId
            destinationViewController.validVerificationCode = self.verificationCode
        }
    }
    
    deinit {
        self.responseData = nil
        self.HUD = nil
        self.verificationType = nil
    }
    
}
