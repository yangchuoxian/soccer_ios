//
//  VTChangeEmailViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangeEmailViewController: UIViewController {
    
    @IBOutlet weak var input_email: UITextField!
    @IBOutlet weak var button_save: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_email, iconName: "at")
        self.input_email.text = Singleton_CurrentUser.sharedInstance.email
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
        self.input_email.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "设置邮箱")
    }
    
    func validateUserInput() {
        let enteredEmail = Toolbox.trim(self.input_email.text!)
        let enteredEmailLength = enteredEmail.characters.count
        if enteredEmailLength > 0 && enteredEmailLength <= 80 && Toolbox.isValidEmail(enteredEmail) {
            Toolbox.toggleButton(self.button_save, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_save, enabled: false)
        }
    }
    
    func updateUserInfo(notification: NSNotification) {
        // unwind navigation controller to the previous view controller
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard itself
        self.input_email.resignFirstResponder()
    }
    
    @IBAction func updateEmail(sender: AnyObject) {
        let newEmail = Toolbox.trim(self.input_email.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("email", infoValue: newEmail)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
