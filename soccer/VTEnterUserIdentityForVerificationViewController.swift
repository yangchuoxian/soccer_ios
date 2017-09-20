//
//  VTSendVerificationCodeViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/8.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTEnterUserIdentityForVerificationViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate {
    
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()
    var recipientEmail = ""
    var recipientPhone = ""
    var recipientUserId = ""
    var verificationType: VerificationCodeType?

    @IBOutlet weak var button_submitEmailOrUsername: UIButton!
    @IBOutlet weak var input_usernameOrEmailOrPhone: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target:self, action: #selector(VTEnterUserIdentityForVerificationViewController.cancelResettingPassword))
        if self.verificationType == .email {    // input field should be username or email input
            Appearance.customizeTextField(self.input_usernameOrEmailOrPhone, iconName: "person")
            self.input_usernameOrEmailOrPhone.keyboardType = .default
            self.input_usernameOrEmailOrPhone.placeholder = "请输入用户名或邮箱地址"
        } else {    // input field should be phone number input
            Appearance.customizeTextField(self.input_usernameOrEmailOrPhone, iconName: "phone")
            self.input_usernameOrEmailOrPhone.keyboardType = .phonePad
            self.input_usernameOrEmailOrPhone.placeholder = "请输入手机号码"
        }
        self.input_usernameOrEmailOrPhone.addTarget(self, action: #selector(VTEnterUserIdentityForVerificationViewController.validateUserInput), for: .editingChanged)
        self.input_usernameOrEmailOrPhone.delegate = self
    }
    
    func cancelResettingPassword() {
        // unwind back to login view controller
        self.performSegue(withIdentifier: "unwindFromEnterUserIdentityToLoginView", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "发送验证码")
    }
    
    func validateUserInput() {
        let enteredString = Toolbox.trim(self.input_usernameOrEmailOrPhone.text!)
        if self.verificationType == .email {    // input must a valid email address or username
            if enteredString.characters.count > 0 {
                Toolbox.toggleButton(self.button_submitEmailOrUsername, enabled: true)
            } else {
                Toolbox.toggleButton(self.button_submitEmailOrUsername, enabled: false)
            }
        } else {    // input must be a valid phone number
            if enteredString.characters.count != 11 {
                Toolbox.toggleButton(self.button_submitEmailOrUsername, enabled: false)
            } else {
                Toolbox.toggleButton(self.button_submitEmailOrUsername, enabled: true)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.input_usernameOrEmailOrPhone.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.input_usernameOrEmailOrPhone {
            if self.button_submitEmailOrUsername.isEnabled {
                self.input_usernameOrEmailOrPhone.resignFirstResponder()
                self.button_submitEmailOrUsername.sendActions(for: .touchUpInside)
                return true
            }
            return false
        }
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitEmailOrUsername(_ sender: AnyObject) {
        let emailOrUsernameOrPhone = Toolbox.trim(self.input_usernameOrEmailOrPhone.text!)
        let connection: NSURLConnection?
        if self.verificationType == .email {
            connection = Toolbox.asyncHttpPostToURL(URLSubmitEmailOrUsernameForVerification, parameters: "emailOrUsername=\(emailOrUsernameOrPhone)", delegate: self)
        } else {
            connection = Toolbox.asyncHttpPostToURL(URLSubmitPhoneNumberForVerification, parameters: "phoneNumber=\(emailOrUsernameOrPhone)", delegate: self)
        }
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        
        let JSONResponse = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
        if JSONResponse != nil {    // send email with verification code succeeded
            if JSONResponse!["recipientEmail"] != nil {
                self.recipientEmail = JSONResponse!["recipientEmail"] as! String
                self.recipientUserId = JSONResponse!["userId"] as! String
                self.performSegue(withIdentifier: "enterVerificationSegue", sender: self)
            } else if JSONResponse!["recipientPhone"] != nil {
                self.recipientPhone = JSONResponse!["recipientPhone"] as! String
                self.recipientUserId = JSONResponse!["userId"] as! String
                self.performSegue(withIdentifier: "enterVerificationSegue", sender: self)
            } else {
                Toolbox.showCustomAlertViewWithImage("unhappy", title: "邮件发送失败")
            }
        } else {
            let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
            self.input_usernameOrEmailOrPhone.text = nil
            Toolbox.toggleButton(self.button_submitEmailOrUsername, enabled: false)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "enterVerificationSegue" {
            let destinationViewController = segue.destination as! VTEnterVerificationCodeViewController
            destinationViewController.verificationType = self.verificationType
            if self.verificationType == .email {
                destinationViewController.destinedPhoneNumberOrEmailAddress = self.recipientEmail
            } else {
                destinationViewController.destinedPhoneNumberOrEmailAddress = self.recipientPhone
            }
            destinationViewController.userId = self.recipientUserId
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.HUD = nil
        self.responseData = nil
        self.verificationType = nil
    }
}
