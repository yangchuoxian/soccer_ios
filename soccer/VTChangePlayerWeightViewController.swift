//
//  VTChangePlayerWeightViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangePlayerWeightViewController: UIViewController {
    
    @IBOutlet weak var input_weight: UITextField!
    @IBOutlet weak var button_submit: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_weight, iconName: "person_2")
        self.input_weight.text = Singleton_CurrentUser.sharedInstance.weight
        // add unit label as rightView of textField input_weight
        Appearance.addRightViewToTextField(self.input_weight, withText: "kg")
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller 
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
        self.input_weight.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "修改体重")
    }
    
    func validateUserInput() {
        let enteredWeight = Toolbox.trim(self.input_weight.text!)
        if enteredWeight.characters.count > 0 && Int(enteredWeight) > 30 && Int(enteredWeight) < 200 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    func updateUserInfo(notification: NSNotification) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_weight.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateWeight(sender: AnyObject) {
        let newWeight = Toolbox.trim(self.input_weight.text!)
        if !Toolbox.isStringValueValid(newWeight) {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请输入体重")
            return
        }
        if Int(newWeight) > 400 {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "请输入有效的体重")
            return
        }
        Singleton_CurrentUser.sharedInstance.updateUserInfo("weight", infoValue: newWeight)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}