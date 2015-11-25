//
//  VTChangePhoneViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangePhoneViewController: UIViewController {
    
    @IBOutlet weak var input_phoneNumber: UITextField!
    @IBOutlet weak var button_save: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_phoneNumber, iconName: "phone")
        if Toolbox.isStringValueValid(Singleton_CurrentUser.sharedInstance.phoneNumber) {
            self.input_phoneNumber.text = Singleton_CurrentUser.sharedInstance.phoneNumber
        }
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
        self.input_phoneNumber.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "更新手机号码")
    }
    
    func validateUserInput() {
        let enteredPhoneLength = Toolbox.trim(self.input_phoneNumber.text!).characters.count
        if enteredPhoneLength == 11 {
            Toolbox.toggleButton(self.button_save, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_save, enabled: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUserInfo(notification: NSNotification) {
        self.navigationController?.popViewControllerAnimated(true)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_phoneNumber.resignFirstResponder()
    }
    
    @IBAction func updatePhoneNumber(sender: AnyObject) {
        let newPhoneNumber = Toolbox.trim(self.input_phoneNumber.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("phoneNumber", infoValue: newPhoneNumber)
    }
    
}
