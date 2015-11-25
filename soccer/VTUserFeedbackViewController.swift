//
//  VTUserFeedbackViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/7/30.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTUserFeedbackViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextViewDelegate {
    
    @IBOutlet weak var textView_feedback: UITextView!
    @IBOutlet weak var button_submit: UIButton!
    
    var HUD: MBProgressHUD?

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeTextView(self.textView_feedback, placeholder: "请输入意见反馈(300字以内)")
        // disable auto inset adjustment so that text inside textView stays at the top in the begining
        self.automaticallyAdjustsScrollViewInsets = false
        self.textView_feedback.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "意见反馈")
    }
    
    func textViewDidChange(textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.TextViewPlaceholder.rawValue)
        if !textView.hasText() {
            placeHolderLabel?.hidden = false
        } else {
            placeHolderLabel?.hidden = true
        }
        
        let enteredFeedbackLength = Toolbox.trim(self.textView_feedback.text).characters.count
        if enteredFeedbackLength > 0 && enteredFeedbackLength < 288 {
            Toolbox.toggleButton(self.button_submit, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_submit, enabled: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.textView_feedback.resignFirstResponder()
    }
    
    @IBAction func submitFeedback(sender: AnyObject) {
        let newFeedback = Toolbox.trim(self.textView_feedback.text)
        let currentUser = Singleton_CurrentUser.sharedInstance
        let connection = Toolbox.asyncHttpPostToURL(URLSubmitFeedback, parameters: "feedback=\(newFeedback)&userId=\(currentUser.userId!)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        // get http response status code
        let httpResponse = response as! NSHTTPURLResponse
        if httpResponse.statusCode == HttpStatusCode.OK.rawValue {  // feedback successfully submitted
            let param = NSDictionary(object: "feedback", forKey: "settings")
        NSNotificationCenter.defaultCenter().postNotificationName("settingsInstructionComplete", object: param)
            // unwind segue, go back to previous view controller
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "提交反馈失败")
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
    }
    
    deinit {
        self.HUD = nil
    }
    
}
