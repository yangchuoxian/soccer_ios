//
//  VTSendApplicationViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/5/16.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTSendApplicationViewController: UIViewController, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextViewDelegate, MBProgressHUDDelegate {
    
    @IBOutlet weak var textView_application: UITextView!
    @IBOutlet weak var button_send: UIButton!
    
    var teamObject: Team!
    var teamCaptainUserId: String!
    var application: String!
    var HUD: MBProgressHUD!
    var responseData: NSMutableData? = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Appearance.customizeNavigationBar(self, title: "申请加入球队")
        self.navigationController!.navigationBar.topItem!.title = ""
        // makes sure the text of textView stays at the top inside the textView
        self.automaticallyAdjustsScrollViewInsets = false
        Appearance.customizeTextView(self.textView_application, placeholder: "请输入申请消息(300字以内)")
        self.textView_application.delegate = self
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.textViewPlaceholder.rawValue)
        if !textView.hasText {
            placeHolderLabel?.isHidden = false
        } else {
            placeHolderLabel?.isHidden = true
        }
        
        let enteredApplicationLength = Toolbox.trim(self.textView_application.text).characters.count
        if enteredApplicationLength > 0 && enteredApplicationLength < 300 {
            Toolbox.toggleButton(self.button_send, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_send, enabled: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // resign the keyboard when tapped somewhere else other than the text field or the keyboard itself
        self.textView_application.resignFirstResponder()
    }
    
    @IBAction func sendApplication(_ sender: AnyObject) {
        self.application = Toolbox.trim(self.textView_application.text)
        let connection = Toolbox.asyncHttpPostToURL(URLSendMessage,
            parameters: "recipientId=\(self.teamCaptainUserId)&messageContent=\(self.application)&type=\(MessageType.application.rawValue)&toTeam=\(self.teamObject.teamId)",
            delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
            self.HUD.delegate = self
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD.hide(true, afterDelay: 0)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD.hide(true, afterDelay: 0)
        self.HUD = nil
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)!
        if (responseStr as String).range(of: "newMessageId") != nil {    // send application succeeded
            // set up HUD to show that application sent successfully
            Toolbox.showCustomAlertViewWithImage("checkmark", title: "申请发送成功")
        } else {    // send application failed with error message
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    /**
     * MBProgressHUD delegate method, invoked automatically when the HUD that shows application sent succeeded was hidden
     */
    func hudWasHidden(_ hud: MBProgressHUD!) {
        // send notification to notify that application has sent successfully
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "applicationSentSuccessfully"),
            object: self.teamObject
        )
        // unwind segue, go back to teams table view controller
        self.performSegue(withIdentifier: "unwindToTeamListFromSendApplicationSegue", sender: self)
    }
    
    deinit {
        self.responseData = nil
    }
    
}
