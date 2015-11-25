//
//  VTChangeNameViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/29.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangeNameViewController: UIViewController {

    @IBOutlet weak var input_name: UITextField!
    @IBOutlet weak var button_save: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_name, iconName: "person_2")
        if Toolbox.isStringValueValid(Singleton_CurrentUser.sharedInstance.name) {
            self.input_name.text = Singleton_CurrentUser.sharedInstance.name
        }
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
        self.input_name.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "设置姓名")
    }
    
    func validateUserInput() {
        let enteredNameLength = Toolbox.trim(self.input_name.text!).characters.count
        if enteredNameLength > 0 && enteredNameLength <= 30 {
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
        self.input_name.resignFirstResponder()
    }
    
    @IBAction func updateName(sender: AnyObject) {
        let newName = Toolbox.trim(self.input_name.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("name", infoValue: newName)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
