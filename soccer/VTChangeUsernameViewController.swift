//
//  VTChangeUsernameViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangeUsernameViewController: UIViewController {

    @IBOutlet weak var input_username: UITextField!
    @IBOutlet weak var button_save: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_username, iconName: "person")
        self.input_username.text = Singleton_CurrentUser.sharedInstance.username
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NotificationCenter.default.addObserver(self, selector: #selector(VTChangeUsernameViewController.updateUserInfo(_:)), name: NSNotification.Name(rawValue: "userInfoUpdated"), object: nil)
        self.input_username.addTarget(self, action: #selector(VTChangeUsernameViewController.validateUserInput), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "修改用户名")
    }
    
    func validateUserInput() {
        let enteredUsernameLength = Toolbox.trim(self.input_username.text!).characters.count
        if enteredUsernameLength > 0 && enteredUsernameLength < 80 {
            Toolbox.toggleButton(self.button_save, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_save, enabled: false)
        }
    }
    
    func updateUserInfo(_ notification: Notification) {
        // unwind navigation controller to the previous view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard iteslf
        self.input_username.resignFirstResponder()
    }
    
    @IBAction func updateUsername(_ sender: AnyObject) {
        let newUsername = Toolbox.trim(self.input_username.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("username", infoValue: newUsername)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
