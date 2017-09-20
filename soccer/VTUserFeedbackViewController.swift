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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Appearance.customizeNavigationBar(self, title: "意见反馈")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.textViewPlaceholder.rawValue)
        if !textView.hasText {
            placeHolderLabel?.isHidden = false
        } else {
            placeHolderLabel?.isHidden = true
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textView_feedback.resignFirstResponder()
    }
    
    @IBAction func submitFeedback(_ sender: AnyObject) {
        let newFeedback = Toolbox.trim(self.textView_feedback.text)
        let currentUser = Singleton_CurrentUser.sharedInstance
        let connection = Toolbox.asyncHttpPostToURL(URLSubmitFeedback, parameters: "feedback=\(newFeedback)&userId=\(currentUser.userId!)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        // get http response status code
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode == HttpStatusCode.ok.rawValue {  // feedback successfully submitted
            let param = NSDictionary(object: "feedback", forKey: "settings" as NSCopying)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "settingsInstructionComplete"), object: param)
            // unwind segue, go back to previous view controller
            self.navigationController?.popViewController(animated: true)
        } else {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "提交反馈失败")
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
    }
    
    deinit {
        self.HUD = nil
    }
    
}
