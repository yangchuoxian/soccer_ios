//
//  VTChangePlayerHeightViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangePlayerHeightViewController: UIViewController {
    
    @IBOutlet weak var input_height: UITextField!
    @IBOutlet weak var button_submit: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_height, iconName: "person_2")
        
        self.input_height.text = Singleton_CurrentUser.sharedInstance.height
        // add unit label as rightView of textField input_height
        Appearance.addRightViewToTextField(self.input_height, withText: "cm")
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
        self.input_height.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "修改身高")
    }
    
    func validateUserInput() {
        let enteredHeight = Toolbox.trim(self.input_height.text!)
        if enteredHeight.characters.count > 0 && Int(enteredHeight) > 20 && Int(enteredHeight) < 250 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    func updateUserInfo(notification: NSNotification) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_height.resignFirstResponder()
    }
    
    @IBAction func updateHeight(sender: AnyObject) {
        let newHeight = Toolbox.trim(self.input_height.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("height", infoValue: newHeight)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
