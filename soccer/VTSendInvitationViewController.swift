//
//  VTSendInvitationViewController.swift
//  soccer
//
//  Created by 杨逴先 on 15/8/2.
//  Copyright (c) 2015年 VisionTech. All rights reserved.
//

import UIKit

class VTSendInvitationViewController: UIViewController, MBProgressHUDDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UITextViewDelegate {
    
    @IBOutlet weak var textView_invitation: UITextView!
    @IBOutlet weak var button_send: UIButton!
    
    var fromTeamId = ""
    var receiverUserObject: User?
    var HUD: MBProgressHUD?
    var responseData: NSMutableData? = NSMutableData()

    override func viewDidLoad() {
        super.viewDidLoad()

        Appearance.customizeNavigationBar(self, title: "组队邀请")
        // makes sure the text of textView stays at the top inside the textView
        self.automaticallyAdjustsScrollViewInsets = false
        Appearance.customizeTextView(self.textView_invitation, placeholder: "请输入组队邀请消息(300字以内)")
        self.textView_invitation.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Get the placeholder label
        let placeHolderLabel = textView.viewWithTag(TagValue.textViewPlaceholder.rawValue)
        if !textView.hasText {
            placeHolderLabel?.isHidden = false
        } else {
            placeHolderLabel?.isHidden = true
        }
        
        let enteredInvitationLength = Toolbox.trim(self.textView_invitation.text).characters.count
        if enteredInvitationLength > 0 && enteredInvitationLength < 300 {
            Toolbox.toggleButton(self.button_send, enabled: true)
        } else {
            Toolbox.toggleButton(self.button_send, enabled: false)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textView_invitation.resignFirstResponder()
    }
    
    @IBAction func sendInvitation(_ sender: AnyObject) {
        let invitationContent = Toolbox.trim(self.textView_invitation.text)
        let connection = Toolbox.asyncHttpPostToURL(URLSendMessage, parameters: "recipientId=\(self.receiverUserObject!.userId)&messageContent=\(invitationContent)&type=\(MessageType.invitation.rawValue)&fromTeam=\(self.fromTeamId)", delegate: self)
        if connection == nil {
            Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络连接失败")
        } else {
            self.HUD = Toolbox.setupCustomProcessingViewWithTitle(title: nil)
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.HUD?.hide(true)
        self.HUD = nil
        Toolbox.showCustomAlertViewWithImage("unhappy", title: "网络超时")
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.HUD?.hide(true)
        self.HUD = nil
        let responseStr = NSString(data: self.responseData! as Data, encoding: String.Encoding.utf8.rawValue)
        if (responseStr as! String).range(of: "newMessageId") != nil {  // send invitation succeeded, server respond back with the invitation(message) create time and message id
            self.performSegue(withIdentifier: "unwindToMembersContainerSegue", sender: self)
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "invitationSentSuccessfully"),
                object: self.receiverUserObject
            )
        } else {    // send invitation failed
            Toolbox.showCustomAlertViewWithImage("unhappy", title: responseStr as! String)
        }
        self.responseData = nil
        self.responseData = NSMutableData()
    }
    
    deinit {
        self.receiverUserObject = nil
        self.HUD = nil
        self.responseData = nil
    }
    
}
