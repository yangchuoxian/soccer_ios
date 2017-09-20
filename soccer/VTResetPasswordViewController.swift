//
//  VTResetPasswordViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var input_oldPassword: UITextField!
    @IBOutlet weak var input_newPassword: UITextField!
    @IBOutlet weak var input_confirmPassword: UITextField!

    @IBOutlet weak var button_submit: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController!.navigationBar.topItem!.title = ""
        Appearance.customizeNavigationBar(self, title: "更改密码")
        
        Appearance.customizeTextField(self.input_oldPassword, iconName: "locked")
        Appearance.customizeTextField(self.input_newPassword, iconName: "key")
        Appearance.customizeTextField(self.input_confirmPassword, iconName: "key")
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTResetPasswordViewController.passwordUpdated(_:)), name: NSNotification.Name(rawValue: "settingsInstructionComplete"), object: nil)
        self.input_oldPassword.addTarget(self, action: #selector(VTResetPasswordViewController.validateUserInput), for: .editingChanged)
        self.input_newPassword.addTarget(self, action: #selector(VTResetPasswordViewController.validateUserInput), for: .editingChanged)
        self.input_confirmPassword.addTarget(self, action: #selector(VTResetPasswordViewController.validateUserInput), for: .editingChanged)
    }
    
    func validateUserInput() {
        let enteredOldPassword = Toolbox.trim(self.input_oldPassword.text!)
        let enteredNewPassword = Toolbox.trim(self.input_newPassword.text!)
        let enteredConfirmPassword = Toolbox.trim(self.input_confirmPassword.text!)
        let enteredOldPasswordLength = enteredOldPassword.characters.count
        let enteredNewPasswordLength = enteredNewPassword.characters.count
        if enteredOldPasswordLength >= 6 && enteredOldPasswordLength <= 20 &&
            enteredNewPasswordLength >= 6 && enteredNewPasswordLength <= 20 &&
            enteredNewPassword == enteredConfirmPassword {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    func passwordUpdated(_ notification: Notification) {
        // unwind navigation controller to the previous view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.input_oldPassword.resignFirstResponder()
        self.input_newPassword.resignFirstResponder()
        self.input_confirmPassword.resignFirstResponder()
    }
    
    @IBAction func submitPasswordChange(_ sender: AnyObject) {
        let oldPassword = Toolbox.trim(self.input_oldPassword.text!)
        let newPassword = Toolbox.trim(self.input_newPassword.text!)
        let confirmPassword = Toolbox.trim(self.input_confirmPassword.text!)
        Singleton_CurrentUser.sharedInstance.updateUserPassword(oldPassword, newPassword: newPassword, confirmPassword: confirmPassword)
    }

}
