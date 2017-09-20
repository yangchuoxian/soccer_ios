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
        NotificationCenter.default.addObserver(self, selector: #selector(VTChangePhoneViewController.updateUserInfo(_:)), name: NSNotification.Name(rawValue: "userInfoUpdated"), object: nil)
        self.input_phoneNumber.addTarget(self, action: #selector(VTChangePhoneViewController.validateUserInput), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    func updateUserInfo(_ notification: Notification) {
        self.navigationController?.popViewController(animated: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.input_phoneNumber.resignFirstResponder()
    }
    
    @IBAction func updatePhoneNumber(_ sender: AnyObject) {
        let newPhoneNumber = Toolbox.trim(self.input_phoneNumber.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("phoneNumber", infoValue: newPhoneNumber)
    }
    
}
