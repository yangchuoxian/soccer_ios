//
//  VTEnterNewPasswordViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/8.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTEnterNewPasswordViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextFieldDelegate {

    @IBOutlet weak var input_newPassword: UITextField!
    @IBOutlet weak var input_confirmNewPassword: UITextField!
    @IBOutlet weak var button_submit: UIButton!
    
    var HUD: MBProgressHUD?
    var userId = ""
    var validVerificationCode = ""
    var newPassword = ""
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_newPassword, iconName: "key")
        Appearance.customizeTextField(self.input_confirmNewPassword, iconName: "key")
        
        // add right button in navigation bar programmatically
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target:self, action: #selector(VTEnterNewPasswordViewController.cancelResettingPassword))
        // empty bar back button text
        self.navigationController!.navigationBar.topItem!.title = ""
        
        self.input_newPassword.addTarget(self, action: #selector(VTEnterNewPasswordViewController.validateUserInput), for: .editingChanged)
        self.input_confirmNewPassword.addTarget(self, action: #selector(VTEnterNewPasswordViewController.validateUserInput), for: .editingChanged)
        
        self.input_newPassword.delegate = self
        self.input_confirmNewPassword.delegate = self
    }
    
    func cancelResettingPassword() {
        self.performSegue(withIdentifier: "unwindFromEnterNewPasswordToLoginView", sender: self)
    }
    
    func validateUserInput() {
        let newPassword = Toolbox.trim(self.input_newPassword.text!)
        let confirmNewPassword = Toolbox.trim(self.input_confirmNewPassword.text!)
        let passwordLength = newPassword.characters.count
        if newPassword == confirmNewPassword && passwordLength >= 6 && passwordLength <= 20 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.input_newPassword {
            self.input_newPassword.resignFirstResponder()
            self.input_confirmNewPassword.becomeFirstResponder()
            return true
        } else if textField == self.input_confirmNewPassword {
            if self.button_submit.isEnabled {
                self.input_confirmNewPassword.resignFirstResponder()
                self.button_submit.sendActions(for: .touchUpInside)
                return true
            }
            return false
        }
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.input_newPassword.resignFirstResponder()
        self.input_confirmNewPassword.resignFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "重置密码")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitNewPassword(_ sender: AnyObject) {
        self.newPassword = Toolbox.trim(self.input_newPassword.text!)
        let connection = Toolbox.asyncHttpPostToURL(
            URLRetrievePassword,
            parameters: Toolbox.addDeviceIDAndDeviceTypeToHttpRequestParameters("newPassword=\(self.newPassword)&userId=\(self.userId)&validVerificationCode=\(self.validVerificationCode)"),
            delegate: self
        )
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
        let userJSON = (try? JSONSerialization.jsonObject(with: self.responseData! as Data, options: .mutableLeaves)) as? [AnyHashable: Any]
        if userJSON != nil {
            if (userJSON!["id"] as? String) == self.userId {  // reset password succeeded, server responded with logged in user json object
                self.input_newPassword.resignFirstResponder()
                self.input_confirmNewPassword.resignFirstResponder()
                Singleton_CurrentUser.sharedInstance.processUserLogin(userJSON!)
            }
        } else {
            let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        
        self.responseData = nil
        self.responseData = NSMutableData()
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
    }
    
}
