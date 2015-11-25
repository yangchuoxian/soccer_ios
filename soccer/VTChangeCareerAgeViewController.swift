//
//  VTChangeCareerAgeViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangeCareerAgeViewController: UIViewController {

    @IBOutlet weak var input_careerAge: UITextField!
    @IBOutlet weak var button_submit: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextField(self.input_careerAge, iconName: "person_2")
        // set up weight text if it exists
        let currentUser = Singleton_CurrentUser.sharedInstance
        self.input_careerAge.text = currentUser.careerAge
        // add unit label as rightView of textField input_weight
        Appearance.addRightViewToTextField(self.input_careerAge, withText: "年")
        
        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
        self.input_careerAge.addTarget(self, action: "validateUserInput", forControlEvents: .EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "更改球龄")
    }
    
    func validateUserInput() {
        let enteredCareerAge = Toolbox.trim(self.input_careerAge.text!)
        if enteredCareerAge.characters.count > 0 && Int(enteredCareerAge) <= 50 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }
    
    func updateUserInfo(notification: NSNotification) {
        // unwind navigation controller to the previous view controller
        self.performSegueWithIdentifier("unwindToUserInfoTableSegue", sender: self)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.input_careerAge.resignFirstResponder()
    }
    
    @IBAction func updateCareerAge(sender: AnyObject) {
        let newCareerAge = Toolbox.trim(self.input_careerAge.text!)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("careerAge", infoValue: newCareerAge)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
