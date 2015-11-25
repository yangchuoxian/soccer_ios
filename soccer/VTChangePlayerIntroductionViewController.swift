//
//  VTChangePlayerIntroductionViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTChangePlayerIntroductionViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView_introduction: UITextView!
    @IBOutlet weak var button_submit: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable auto inset adjustment so that inside textView stays at the top in the begining
        self.automaticallyAdjustsScrollViewInsets = false
        let currentUser = Singleton_CurrentUser.sharedInstance
        if Toolbox.isStringValueValid(currentUser.introduction) {
            self.textView_introduction.text = currentUser.introduction
        }
        Appearance.customizeTextView(self.textView_introduction, placeholder: "请输入个人简介(300字以内)")
        self.textView_introduction.delegate = self

        // Get the placeholder label, if the introduction text is not empty, we should hide the placeholder label
        let placeHolderLabel = self.textView_introduction.viewWithTag(TagValue.TextViewPlaceholder.rawValue)
        if self.textView_introduction.text.characters.count > 0 {
            placeHolderLabel?.hidden = true
        }

        // listen to userInfoUpdated message and handles it by unwinding the navigation controller to the previous view controller
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUserInfo:", name: "userInfoUpdated", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "个人简介")
    }
    
    func textViewDidChange(textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.TextViewPlaceholder.rawValue)
        if !textView.hasText() {
            placeHolderLabel?.hidden = false
        } else {
            placeHolderLabel?.hidden = true
        }
        
        let enteredIntroductionLength = Toolbox.trim(self.textView_introduction.text).characters.count
        if enteredIntroductionLength > 0 && enteredIntroductionLength < 300 {
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
        self.textView_introduction.resignFirstResponder()
    }
    
    @IBAction func updateIntroduction(sender: AnyObject) {
        let newIntroduction = Toolbox.trim(self.textView_introduction.text)
        Singleton_CurrentUser.sharedInstance.updateUserInfo("introduction", infoValue: newIntroduction)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
